defmodule LiveFrames.Catalogue.LifecycleTest do
  use ExUnit.Case, async: true

  alias LiveFrames.Catalogue.Lifecycle
  alias LiveFrames.Catalogue.Manifest

  @id "live_frames.component.synthetic"
  @kind "component"
  @evidence ["catalogue-guard:first", "catalogue-guard:second"]

  @approved_transitions [
    {"validate", "DRAFT", "VALIDATED"},
    {"review", "VALIDATED", "REVIEWED"},
    {"approve", "REVIEWED", "APPROVED"},
    {"release", "APPROVED", "RELEASED"},
    {"publish_new_version", "RELEASED", "RELEASED"},
    {"deprecate", "RELEASED", "DEPRECATED"},
    {"retire", "DEPRECATED", "RETIRED"},
    {"withdraw", "DRAFT", "WITHDRAWN"},
    {"withdraw", "VALIDATED", "WITHDRAWN"},
    {"withdraw", "REVIEWED", "WITHDRAWN"},
    {"withdraw", "APPROVED", "WITHDRAWN"}
  ]

  @lifecycle_actions ~w(
    validate
    review
    approve
    release
    publish_new_version
    deprecate
    retire
    withdraw
  )

  @matrix_states @lifecycle_actions
                 |> then(fn _ ->
                   ~w(DRAFT VALIDATED REVIEWED APPROVED RELEASED DEPRECATED RETIRED WITHDRAWN)
                 end)

  @invalid_states ~w(GENERATED UNKNOWN)

  @allowed_from_pairs MapSet.new([
                        {"validate", "DRAFT"},
                        {"review", "VALIDATED"},
                        {"approve", "REVIEWED"},
                        {"release", "APPROVED"},
                        {"publish_new_version", "RELEASED"},
                        {"deprecate", "RELEASED"},
                        {"retire", "DEPRECATED"},
                        {"withdraw", "DRAFT"},
                        {"withdraw", "VALIDATED"},
                        {"withdraw", "REVIEWED"},
                        {"withdraw", "APPROVED"}
                      ])

  describe "approved transitions" do
    for {action, from, to} <- @approved_transitions do
      test "#{from} + #{action} → #{to}" do
        manifest = synthetic_manifest(unquote(from))

        assert {:ok, updated} =
                 Lifecycle.transition(manifest, unquote(action), {:ok, @evidence})

        assert updated.state == unquote(to)

        assert updated.lifecycle["last_transition"] == %{
                 "action" => unquote(action),
                 "from" => unquote(from),
                 "to" => unquote(to),
                 "evidence_refs" => @evidence
               }

        assert preserved_unrelated_fields?(manifest, updated)
      end
    end
  end

  describe "admission" do
    test "valid DRAFT candidate records admit_to_catalogue transition" do
      manifest = draft_candidate_without_transition()

      assert {:ok, updated} =
               Lifecycle.transition(manifest, "admit_to_catalogue", {:ok, ["admission:ok"]})

      assert updated.state == "DRAFT"

      assert updated.lifecycle["last_transition"] == %{
               "action" => "admit_to_catalogue",
               "from" => nil,
               "to" => "DRAFT",
               "evidence_refs" => ["admission:ok"]
             }
    end

    test "preserves unrelated lifecycle keys on admission" do
      manifest =
        synthetic_manifest("DRAFT")
        |> Map.put(:lifecycle, %{"note" => "reserved"})

      assert {:ok, updated} =
               Lifecycle.transition(manifest, "admit_to_catalogue", {:ok, ["admission:ok"]})

      assert updated.lifecycle["note"] == "reserved"
    end

    test "rejects re-admission when last_transition exists" do
      manifest =
        synthetic_manifest("DRAFT")
        |> Map.put(:lifecycle, %{"last_transition" => %{"action" => "admit_to_catalogue"}})

      assert {:error, diagnostic} =
               Lifecycle.transition(manifest, "admit_to_catalogue", {:ok, ["admission:ok"]})

      assert diagnostic.code == "catalogue.lifecycle.admission_invalid"
      assert manifest.state == "DRAFT"
    end

    test "rejects admission for non-DRAFT state" do
      manifest = synthetic_manifest("VALIDATED")

      assert {:error, diagnostic} =
               Lifecycle.transition(manifest, "admit_to_catalogue", {:ok, ["admission:ok"]})

      assert diagnostic.code == "catalogue.lifecycle.admission_invalid"
    end

    test "failed admission guard leaves manifest unchanged" do
      manifest = draft_candidate_without_transition()

      guard_failure = {:error, [%{code: "guard.failed", path: "guard", message: "nope"}]}

      assert ^guard_failure =
               Lifecycle.transition(manifest, "admit_to_catalogue", guard_failure)

      assert manifest.state == "DRAFT"
      assert manifest.lifecycle == nil
    end
  end

  describe "invalid transition matrix" do
    for action <- @lifecycle_actions,
        from <- @matrix_states ++ @invalid_states do
      unless MapSet.member?(@allowed_from_pairs, {action, from}) do
        test "rejects #{action} from #{from}" do
          manifest = synthetic_manifest(unquote(from))

          assert {:error, diagnostic} =
                   Lifecycle.transition(manifest, unquote(action), {:ok, @evidence})

          code =
            if unquote(from) in unquote(@invalid_states) do
              "catalogue.lifecycle.state_invalid"
            else
              "catalogue.lifecycle.transition_invalid"
            end

          assert diagnostic.code == code
        end
      end
    end

    for terminal <- ~w(WITHDRAWN RETIRED) do
      for action <- @lifecycle_actions do
        test "terminal #{terminal} rejects #{action}" do
          manifest = synthetic_manifest(unquote(terminal))

          assert {:error, diagnostic} =
                   Lifecycle.transition(manifest, unquote(action), {:ok, @evidence})

          assert diagnostic.code == "catalogue.lifecycle.transition_invalid"
        end
      end

      test "terminal #{terminal} rejects admit_to_catalogue" do
        manifest = synthetic_manifest(unquote(terminal))

        assert {:error, diagnostic} =
                 Lifecycle.transition(manifest, "admit_to_catalogue", {:ok, @evidence})

        assert diagnostic.code == "catalogue.lifecycle.admission_invalid"
      end
    end

    test "rejects unknown action string" do
      manifest = synthetic_manifest("DRAFT")

      assert {:error, diagnostic} =
               Lifecycle.transition(manifest, "force_release", {:ok, @evidence})

      assert diagnostic.code == "catalogue.lifecycle.action_invalid"
    end

    test "rejects non-string action" do
      manifest = synthetic_manifest("DRAFT")

      assert {:error, diagnostic} = Lifecycle.transition(manifest, :validate, {:ok, @evidence})
      assert diagnostic.code == "catalogue.lifecycle.action_invalid"
    end
  end

  describe "guard results" do
    test "passes guard failure through for valid transition" do
      manifest = synthetic_manifest("DRAFT")
      guard_failure = {:error, [%{code: "guard.failed", path: "fingerprint", message: "bad"}]}

      assert ^guard_failure = Lifecycle.transition(manifest, "validate", guard_failure)

      assert manifest.state == "DRAFT"
      assert manifest.lifecycle == %{"prior" => "unchanged"}
    end

    test "malformed guard result fails deterministically" do
      manifest = synthetic_manifest("DRAFT")

      for guard <- [:ok, {:ok, "not-a-list"}, {:error}, {:maybe, []}] do
        assert {:error, diagnostic} = Lifecycle.transition(manifest, "validate", guard)
        assert diagnostic.code == "catalogue.lifecycle.guard_result_invalid"
        assert manifest.state == "DRAFT"
      end
    end

    test "rejects empty evidence reference member" do
      manifest = synthetic_manifest("DRAFT")

      assert {:error, diagnostic} =
               Lifecycle.transition(manifest, "validate", {:ok, ["valid", ""]})

      assert diagnostic.code == "catalogue.lifecycle.evidence_refs_invalid"
      assert diagnostic.path == "lifecycle.last_transition.evidence_refs[1]"
    end

    test "rejects invalid UTF-8 evidence reference member" do
      manifest = synthetic_manifest("DRAFT")
      invalid_ref = <<0xFF>>

      assert {:error, diagnostic} =
               Lifecycle.transition(manifest, "validate", {:ok, ["valid", invalid_ref]})

      assert diagnostic.code == "catalogue.lifecycle.evidence_refs_invalid"
      assert diagnostic.path == "lifecycle.last_transition.evidence_refs[1]"
      assert manifest.state == "DRAFT"
      assert manifest.lifecycle == %{"prior" => "unchanged"}
    end

    test "rejects non-string evidence reference member" do
      manifest = synthetic_manifest("DRAFT")

      assert {:error, diagnostic} =
               Lifecycle.transition(manifest, "validate", {:ok, ["valid", 42]})

      assert diagnostic.code == "catalogue.lifecycle.evidence_refs_invalid"
    end

    test "rejects non-list evidence refs" do
      manifest = synthetic_manifest("DRAFT")

      assert {:error, diagnostic} =
               Lifecycle.transition(manifest, "validate", {:ok, "not-a-list"})

      assert diagnostic.code == "catalogue.lifecycle.guard_result_invalid"
    end

    test "preserves evidence reference order" do
      refs = ["z-last", "a-first", "m-middle"]
      manifest = synthetic_manifest("DRAFT")

      assert {:ok, updated} =
               Lifecycle.transition(manifest, "validate", {:ok, refs})

      assert updated.lifecycle["last_transition"]["evidence_refs"] == refs
    end

    test "does not create atoms from action or evidence strings" do
      action_marker = "lifecycle_action_#{System.unique_integer([:positive, :monotonic])}"
      evidence_marker = "lifecycle_evidence_#{System.unique_integer([:positive, :monotonic])}"

      assert_raise ArgumentError, fn ->
        String.to_existing_atom(action_marker)
      end

      assert_raise ArgumentError, fn ->
        String.to_existing_atom(evidence_marker)
      end

      manifest = synthetic_manifest("DRAFT")

      assert {:error, diagnostic} =
               Lifecycle.transition(manifest, action_marker, {:ok, [evidence_marker]})

      assert diagnostic.code == "catalogue.lifecycle.action_invalid"

      assert_raise ArgumentError, fn ->
        String.to_existing_atom(action_marker)
      end

      assert_raise ArgumentError, fn ->
        String.to_existing_atom(evidence_marker)
      end
    end
  end

  describe "snapshot validation" do
    test "accepts an admitted DRAFT snapshot" do
      manifest =
        snapshot_manifest(
          "DRAFT",
          snapshot_transition("admit_to_catalogue", nil, "DRAFT", [])
        )

      assert :ok = validate_snapshot(manifest)
    end

    for {action, from, to} <- @approved_transitions do
      test "accepts #{from} + #{action} snapshot ending at #{to}" do
        manifest =
          snapshot_manifest(
            unquote(to),
            snapshot_transition(unquote(action), unquote(from), unquote(to))
          )

        assert :ok = validate_snapshot(manifest)
      end
    end

    test "rejects non-Manifest input with one root diagnostic" do
      for input <- [nil, %{}, "manifest", 42] do
        assert_snapshot_error(
          input,
          "catalogue.lifecycle.snapshot_invalid",
          "$"
        )
      end
    end

    test "rejects invalid current states" do
      for state <- ["GENERATED", "UNKNOWN", "", nil, :released] do
        manifest = snapshot_manifest(state, snapshot_transition("validate", "DRAFT", "VALIDATED"))

        assert_snapshot_error(manifest, "catalogue.lifecycle.state_invalid", "state")
      end
    end

    test "requires lifecycle to be a map" do
      for lifecycle <- [nil, [], "lifecycle", 42] do
        manifest = Map.put(synthetic_manifest("DRAFT"), :lifecycle, lifecycle)

        assert_snapshot_error(
          manifest,
          "catalogue.lifecycle.snapshot_invalid",
          "lifecycle"
        )
      end
    end

    test "requires a non-null map last_transition" do
      for lifecycle <- [
            %{},
            %{"last_transition" => nil},
            %{"last_transition" => "record"},
            %{"last_transition" => []},
            %{"last_transition" => 42}
          ] do
        manifest = Map.put(synthetic_manifest("DRAFT"), :lifecycle, lifecycle)

        assert_snapshot_error(
          manifest,
          "catalogue.lifecycle.last_transition_invalid",
          "lifecycle.last_transition"
        )
      end
    end

    test "requires exactly four string-keyed last_transition fields" do
      valid = snapshot_transition("review", "VALIDATED", "REVIEWED")

      invalid_records = [
        Map.delete(valid, "evidence_refs"),
        Map.put(valid, "timestamp", "2026-09-28T00:00:00Z"),
        %{
          :action => "review",
          :from => "VALIDATED",
          :to => "REVIEWED",
          :evidence_refs => @evidence
        },
        %{
          "action" => "review",
          :from => "VALIDATED",
          "to" => "REVIEWED",
          "evidence_refs" => @evidence
        }
      ]

      for last_transition <- invalid_records do
        manifest = snapshot_manifest("REVIEWED", last_transition)

        assert_snapshot_error(
          manifest,
          "catalogue.lifecycle.last_transition_invalid",
          "lifecycle.last_transition"
        )
      end
    end

    test "accepts unrelated outer lifecycle keys" do
      manifest =
        snapshot_manifest(
          "REVIEWED",
          snapshot_transition("review", "VALIDATED", "REVIEWED"),
          %{"note" => "reserved"}
        )

      assert :ok = validate_snapshot(manifest)
    end

    test "requires valid UTF-8 action, from, and to strings" do
      invalid_utf8 = <<0xFF>>

      invalid_fields = [
        {"action", invalid_utf8},
        {"action", 42},
        {"from", invalid_utf8},
        {"from", 42},
        {"from", nil},
        {"to", invalid_utf8},
        {"to", 42}
      ]

      for {field, value} <- invalid_fields do
        last_transition =
          snapshot_transition("review", "VALIDATED", "REVIEWED")
          |> Map.put(field, value)

        manifest = snapshot_manifest("REVIEWED", last_transition)

        assert_snapshot_error(
          manifest,
          "catalogue.lifecycle.snapshot_transition_invalid",
          "lifecycle.last_transition.#{field}"
        )
      end
    end

    test "rejects unapproved actions" do
      for action <- ["force_release", "reopen", "revive", "publish"] do
        manifest =
          snapshot_manifest("RELEASED", snapshot_transition(action, "APPROVED", "RELEASED"))

        assert_snapshot_error(manifest, "catalogue.lifecycle.action_invalid", "action")
      end
    end

    test "rejects unknown source and target states" do
      unknown_source = snapshot_transition("review", "GENERATED", "REVIEWED")
      unknown_target = snapshot_transition("validate", "DRAFT", "GENERATED")

      assert_snapshot_error(
        snapshot_manifest("REVIEWED", unknown_source),
        "catalogue.lifecycle.snapshot_transition_invalid",
        "lifecycle.last_transition"
      )

      assert_snapshot_error(
        snapshot_manifest("VALIDATED", unknown_target),
        "catalogue.lifecycle.snapshot_transition_invalid",
        "lifecycle.last_transition.to"
      )
    end

    test "rejects normal transitions with nil from" do
      manifest = snapshot_manifest("VALIDATED", snapshot_transition("validate", nil, "VALIDATED"))

      assert_snapshot_error(
        manifest,
        "catalogue.lifecycle.snapshot_transition_invalid",
        "lifecycle.last_transition.from"
      )
    end

    test "rejects impossible action and source pairs" do
      manifest =
        snapshot_manifest("RELEASED", snapshot_transition("release", "REVIEWED", "RELEASED"))

      assert_snapshot_error(
        manifest,
        "catalogue.lifecycle.snapshot_transition_invalid",
        "lifecycle.last_transition"
      )
    end

    test "rejects a stored target that differs from the matrix target" do
      manifest =
        snapshot_manifest("REVIEWED", snapshot_transition("validate", "DRAFT", "REVIEWED"))

      assert_snapshot_error(
        manifest,
        "catalogue.lifecycle.snapshot_transition_invalid",
        "lifecycle.last_transition.to"
      )
    end

    test "rejects a valid transition that does not end at the current state" do
      manifest =
        snapshot_manifest("APPROVED", snapshot_transition("review", "VALIDATED", "REVIEWED"))

      assert_snapshot_error(
        manifest,
        "catalogue.lifecycle.snapshot_state_mismatch",
        "state"
      )
    end

    test "rejects a DRAFT state with a validate transition ending at VALIDATED" do
      manifest = snapshot_manifest("DRAFT", snapshot_transition("validate", "DRAFT", "VALIDATED"))

      assert_snapshot_error(
        manifest,
        "catalogue.lifecycle.snapshot_state_mismatch",
        "state"
      )
    end

    test "requires admission to be exactly not admitted to DRAFT" do
      invalid_records = [
        {
          "DRAFT",
          snapshot_transition("admit_to_catalogue", "DRAFT", "DRAFT"),
          "catalogue.lifecycle.snapshot_transition_invalid",
          "lifecycle.last_transition"
        },
        {
          "VALIDATED",
          snapshot_transition("admit_to_catalogue", nil, "DRAFT"),
          "catalogue.lifecycle.snapshot_state_mismatch",
          "state"
        }
      ]

      for {state, last_transition, code, path} <- invalid_records do
        manifest = snapshot_manifest(state, last_transition)

        assert_snapshot_error(
          manifest,
          code,
          path
        )
      end
    end

    test "accepts empty and duplicate evidence references without changing order" do
      for evidence_refs <- [[], ["evidence:a", "evidence:a"], ["z", "a", "z"]] do
        last_transition = snapshot_transition("validate", "DRAFT", "VALIDATED", evidence_refs)
        manifest = snapshot_manifest("VALIDATED", last_transition)

        assert :ok = validate_snapshot(manifest)
        assert manifest.lifecycle["last_transition"]["evidence_refs"] == evidence_refs
      end
    end

    test "rejects invalid evidence containers and members" do
      invalid_evidence_refs = [
        {nil, "lifecycle.last_transition.evidence_refs"},
        {"evidence", "lifecycle.last_transition.evidence_refs"},
        {42, "lifecycle.last_transition.evidence_refs"},
        {["valid", 42], "lifecycle.last_transition.evidence_refs[1]"},
        {["valid", ""], "lifecycle.last_transition.evidence_refs[1]"},
        {["valid" | :improper_tail], "lifecycle.last_transition.evidence_refs"}
      ]

      for {evidence_refs, path} <- invalid_evidence_refs do
        last_transition = snapshot_transition("validate", "DRAFT", "VALIDATED", evidence_refs)
        manifest = snapshot_manifest("VALIDATED", last_transition)

        assert_snapshot_error(
          manifest,
          "catalogue.lifecycle.evidence_refs_invalid",
          path
        )
      end
    end

    test "rejects invalid UTF-8 evidence members without raising" do
      invalid_ref = <<0xFF>>

      manifest =
        snapshot_manifest(
          "VALIDATED",
          snapshot_transition("validate", "DRAFT", "VALIDATED", [invalid_ref])
        )

      assert_snapshot_error(
        manifest,
        "catalogue.lifecycle.evidence_refs_invalid",
        "lifecycle.last_transition.evidence_refs[0]"
      )
    end

    test "accepts a decoded manifest without lifecycle at the schema boundary, then rejects its snapshot" do
      assert {:ok, manifest} = Manifest.decode(Jason.encode!(minimal_manifest_json()))
      assert manifest.lifecycle == nil

      assert_snapshot_error(
        manifest,
        "catalogue.lifecycle.snapshot_invalid",
        "lifecycle"
      )
    end

    test "accepts a decoded empty lifecycle at the schema boundary, then rejects its snapshot" do
      json = minimal_manifest_json() |> Map.put("lifecycle", %{}) |> Jason.encode!()

      assert {:ok, manifest} = Manifest.decode(json)
      assert manifest.lifecycle == %{}

      assert_snapshot_error(
        manifest,
        "catalogue.lifecycle.last_transition_invalid",
        "lifecycle.last_transition"
      )
    end

    test "does not change the manifest on success or failure" do
      valid =
        snapshot_manifest("RELEASED", snapshot_transition("release", "APPROVED", "RELEASED"))

      invalid =
        snapshot_manifest("RELEASED", snapshot_transition("release", "REVIEWED", "RELEASED"))

      original_valid = valid
      original_invalid = invalid

      assert :ok = validate_snapshot(valid)
      assert valid == original_valid

      assert {:error, [_diagnostic]} = validate_snapshot(invalid)
      assert invalid == original_invalid
    end
  end

  defp draft_candidate_without_transition do
    synthetic_manifest("DRAFT")
    |> Map.put(:lifecycle, nil)
  end

  defp synthetic_manifest(state) do
    %Manifest{
      schema_version: 1,
      id: @id,
      kind: @kind,
      display_name: "Synthetic",
      state: state,
      component: %{"module" => "LiveFrames.Components.Synthetic", "function" => "synthetic"},
      storybook: %{"module" => "LiveFrames.Stories.Synthetic"},
      docs: %{"guide" => "docs/synthetic.md"},
      provenance: %{"source" => "synthetic"},
      contract: %{"fingerprint" => "fp", "fingerprint_algorithm" => "v1"},
      distribution: %{"library" => %{"supported" => false}},
      release: %{"version" => "1.0.0"},
      introduced_in_package: "0.1.0",
      last_changed_in_package: "0.2.0",
      deprecation: %{"reason" => "none"},
      superseded_by: nil,
      lifecycle: %{"prior" => "unchanged"}
    }
  end

  defp validate_snapshot(manifest), do: Lifecycle.validate_snapshot(manifest)

  defp snapshot_manifest(state, last_transition, lifecycle_extra \\ %{}) do
    lifecycle = Map.put(lifecycle_extra, "last_transition", last_transition)
    Map.put(synthetic_manifest(state), :lifecycle, lifecycle)
  end

  defp snapshot_transition(action, from, to, evidence_refs \\ @evidence) do
    %{
      "action" => action,
      "from" => from,
      "to" => to,
      "evidence_refs" => evidence_refs
    }
  end

  defp assert_snapshot_error(manifest, code, path) do
    assert {:error, [diagnostic]} = validate_snapshot(manifest)
    assert diagnostic.code == code
    assert diagnostic.path == path
  end

  defp minimal_manifest_json do
    %{
      "schema_version" => 1,
      "id" => @id,
      "kind" => @kind,
      "display_name" => "Synthetic component",
      "state" => "DRAFT",
      "component" => %{
        "module" => "LiveFrames.Components.Synthetic",
        "function" => "synthetic"
      },
      "storybook" => %{"module" => "LiveFrames.Stories.Synthetic"},
      "docs" => %{},
      "provenance" => %{}
    }
  end

  defp preserved_unrelated_fields?(before, updated) do
    before.id == updated.id and
      before.kind == updated.kind and
      before.display_name == updated.display_name and
      before.component == updated.component and
      before.contract == updated.contract and
      before.storybook == updated.storybook and
      before.docs == updated.docs and
      before.provenance == updated.provenance and
      before.distribution == updated.distribution and
      before.release == updated.release and
      before.introduced_in_package == updated.introduced_in_package and
      before.last_changed_in_package == updated.last_changed_in_package and
      before.deprecation == updated.deprecation and
      before.superseded_by == updated.superseded_by and
      updated.lifecycle["prior"] == "unchanged"
  end
end
