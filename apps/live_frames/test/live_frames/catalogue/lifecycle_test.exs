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
