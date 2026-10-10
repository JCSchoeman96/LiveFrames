defmodule LiveFrames.Behavior.SerializerTest do
  use ExUnit.Case, async: true

  alias LiveFrames.Behavior.Contract
  alias LiveFrames.Behavior.Diagnostic
  alias LiveFrames.Behavior.Binding.FocusPolicy
  alias LiveFrames.Behavior.Binding
  alias LiveFrames.Behavior.Binding.ControlledTarget
  alias LiveFrames.Behavior.Binding.PrimitiveRef
  alias LiveFrames.Behavior.Binding.ResponsiveBehaviorOverride
  alias LiveFrames.Behavior.Binding.Trigger
  alias LiveFrames.IR.SourceTrace
  alias LiveFrames.Behavior.Serializer
  alias LiveFrames.IR.Identity

  @identity %Identity{
    ir_version: "3.0.0",
    canonicalization_id: "lf-ir-serializer-v1",
    digest_algorithm: "sha-256",
    digest: String.duplicate("a", 64)
  }

  test "exposes the BehaviorContract canonicalization algorithm" do
    assert Serializer.algorithm() == "lf-behavior-v1-jcs-sha256"
  end

  test "encodes an empty contract with every top-level field present" do
    assert {:ok,
            "{\"behavior_contract_format_version\":\"1.0.0\",\"bindings\":[],\"design_document_identity\":{\"canonicalization_id\":\"lf-ir-serializer-v1\",\"digest\":\"aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa\",\"digest_algorithm\":\"sha-256\",\"ir_version\":\"3.0.0\"},\"diagnostics\":[],\"provenance\":{}}"} =
             Serializer.encode(%Contract{design_document_identity: @identity})
  end

  test "serializes a persisted binding with the complete PrimitiveRef and explicit nulls" do
    binding = %Binding{
      binding_id: "bnd_" <> String.duplicate("a", 64),
      ordinal: 0,
      primitive_ref: %PrimitiveRef{kind: "disclosure", definition_version: "1.0.0"},
      owner_node_id: "node-owner",
      binding_role: "primary"
    }

    contract = %Contract{design_document_identity: @identity, bindings: [binding]}

    expected =
      "{\"behavior_contract_format_version\":\"1.0.0\",\"bindings\":[{\"binding_id\":\"bnd_aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa\",\"binding_role\":\"primary\",\"controlled_targets\":[],\"diagnostics\":[],\"focus_policy\":null,\"initial_state\":null,\"keyboard_policy\":null,\"motion_policy\":null,\"ordinal\":0,\"owner_node_id\":\"node-owner\",\"primitive_policy_values\":{},\"primitive_ref\":{\"definition_version\":\"1.0.0\",\"kind\":\"disclosure\"},\"provenance\":{},\"responsive_overrides\":[],\"source_trace\":null,\"timer_policy\":null,\"triggers\":[]}],\"design_document_identity\":{\"canonicalization_id\":\"lf-ir-serializer-v1\",\"digest\":\"aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa\",\"digest_algorithm\":\"sha-256\",\"ir_version\":\"3.0.0\"},\"diagnostics\":[],\"provenance\":{}}"

    assert {:ok, ^expected} = Serializer.encode(contract)
  end

  test "rejects malformed persisted binding identities" do
    binding = %Binding{
      binding_id: "bnd_not-a-digest",
      ordinal: 0,
      primitive_ref: %PrimitiveRef{kind: "disclosure", definition_version: "1.0.0"},
      owner_node_id: "node-owner",
      binding_role: "primary"
    }

    assert {:error,
            [
              %{
                code: "behavior.binding.identity_invalid",
                category: "identity",
                binding_id: nil
              }
            ]} =
             Serializer.encode(%Contract{
               design_document_identity: @identity,
               bindings: [binding]
             })
  end

  test "rejects unsupported contract formats and malformed DesignDocument identities" do
    assert {:error, [%{code: "behavior.contract.invalid", category: "structure"}]} =
             Serializer.encode(:not_a_contract)

    assert {:error, [%{code: "behavior.contract.format_unsupported", category: "structure"}]} =
             Serializer.encode(%Contract{
               contract_format_version: "2.0.0",
               design_document_identity: @identity
             })

    invalid_identities = [
      nil,
      %Identity{@identity | canonicalization_id: "unknown"},
      %Identity{@identity | digest_algorithm: "sha-512"},
      %Identity{@identity | digest: String.duplicate("A", 64)}
    ]

    for identity <- invalid_identities do
      assert {:error, [%{code: "behavior.contract.identity_invalid", category: "identity"}]} =
               Serializer.encode(%Contract{design_document_identity: identity})
    end
  end

  test "rejects unassigned bindings, duplicate IDs, and B1-invalid persisted structure" do
    assert {:error, [%{code: "behavior.binding.identity_invalid", category: "identity"}]} =
             Serializer.encode(%Contract{
               design_document_identity: @identity,
               bindings: [%{persisted_binding("a", 0) | ordinal: nil}]
             })

    duplicate = persisted_binding("a", 0)

    assert {:error, [%{code: "behavior.binding.identity_invalid", category: "identity"}]} =
             Serializer.encode(%Contract{
               design_document_identity: @identity,
               bindings: [duplicate, duplicate]
             })

    invalid_structure =
      persisted_binding("a", 0, primitive_policy_values: %{not_a_string_key: true})

    assert {:error, [%{code: "behavior.binding.invalid", category: "structure"}]} =
             Serializer.encode(%Contract{
               design_document_identity: @identity,
               bindings: [invalid_structure]
             })
  end

  test "rejects improper binding collections without raising" do
    binding = persisted_binding("a", 0)

    assert {:error, [%{code: "behavior.contract.invalid", category: "structure"}]} =
             Serializer.encode(%Contract{
               design_document_identity: @identity,
               bindings: [binding | :invalid_tail]
             })

    assert {:error, [%{code: "behavior.binding.invalid", category: "structure"}]} =
             Serializer.encode(%Contract{
               design_document_identity: @identity,
               bindings: [
                 persisted_binding("a", 0, triggers: [%Trigger{kind: "activate"} | :invalid_tail])
               ]
             })
  end

  test "orders bindings, triggers, targets, and responsive overrides deterministically" do
    first =
      persisted_binding("a", 0,
        triggers: [trigger("activate", "node-z"), trigger("activate", "node-a")],
        controlled_targets: [target("content", "node-z"), target("label", "node-a")],
        responsive_overrides: [override("wide"), override("compact")]
      )

    reordered =
      persisted_binding("a", 0,
        triggers: [trigger("activate", "node-a"), trigger("activate", "node-z")],
        controlled_targets: [target("label", "node-a"), target("content", "node-z")],
        responsive_overrides: [override("compact"), override("wide")]
      )

    other = persisted_binding("b", 1)

    original = %Contract{design_document_identity: @identity, bindings: [first, other]}

    reordered_contract = %Contract{
      design_document_identity: @identity,
      bindings: [other, reordered]
    }

    assert {:ok, bytes} = Serializer.encode(original)
    assert {:ok, ^bytes} = Serializer.encode(reordered_contract)
    assert {:ok, digest} = Serializer.digest(original)
    assert {:ok, ^digest} = Serializer.digest(reordered_contract)
  end

  test "serializes SourceTrace and sorts its set-like source classes" do
    trace = %SourceTrace{
      source_type: "builder",
      source_id: "source-1",
      source_path: "inert/source/path",
      source_name: "Hero",
      source_classes: ["zeta", "alpha"],
      source_settings: %{"sequence" => ["second", "first"]},
      adapter: "adapter",
      adapter_version: "1",
      inference: "observed",
      metadata: %{"evidence" => "opaque"}
    }

    reordered_classes = %{trace | source_classes: ["alpha", "zeta"]}

    original = %Contract{
      design_document_identity: @identity,
      bindings: [persisted_binding("a", 0, source_trace: trace)]
    }

    reordered = %Contract{
      design_document_identity: @identity,
      bindings: [persisted_binding("a", 0, source_trace: reordered_classes)]
    }

    assert {:ok, bytes} = Serializer.encode(original)

    assert {:ok, ^bytes} = Serializer.encode(reordered)
    assert {:ok, digest} = Serializer.digest(original)
    assert {:ok, ^digest} = Serializer.digest(reordered)
  end

  test "rejects duplicate SourceTrace classes" do
    trace = %SourceTrace{source_classes: ["same", "same"]}

    assert {:error, [%{code: "behavior.source_trace.invalid", category: "provenance"}]} =
             Serializer.encode(%Contract{
               design_document_identity: @identity,
               bindings: [persisted_binding("a", 0, source_trace: trace)]
             })
  end

  test "rejects improper SourceTrace class lists without raising" do
    trace = %SourceTrace{source_classes: ["valid" | :invalid_tail]}

    assert {:error, [%{code: "behavior.source_trace.invalid", category: "provenance"}]} =
             Serializer.encode(%Contract{
               design_document_identity: @identity,
               bindings: [persisted_binding("a", 0, source_trace: trace)]
             })
  end

  test "encodes null SourceTrace scalars and rejects malformed source trace values" do
    assert {:ok, bytes} =
             Serializer.encode(%Contract{
               design_document_identity: @identity,
               bindings: [persisted_binding("a", 0, source_trace: %SourceTrace{})]
             })

    source_trace = bytes |> Jason.decode!() |> get_in(["bindings", Access.at(0), "source_trace"])

    assert source_trace == %{
             "source_type" => nil,
             "source_id" => nil,
             "source_path" => nil,
             "source_name" => nil,
             "source_classes" => [],
             "source_settings" => %{},
             "adapter" => nil,
             "adapter_version" => nil,
             "inference" => nil,
             "metadata" => %{}
           }

    invalid_trace = %SourceTrace{source_settings: %{"unsafe" => 1.5}}

    assert {:error, [%{code: "behavior.source_trace.invalid", category: "provenance"}]} =
             Serializer.encode(%Contract{
               design_document_identity: @identity,
               bindings: [persisted_binding("a", 0, source_trace: invalid_trace)]
             })
  end

  test "preserves provenance and policy array order in contract digests" do
    base = persisted_binding("a", 0, primitive_policy_values: %{"sequence" => ["a", "b"]})
    reverse_policy = %{base | primitive_policy_values: %{"sequence" => ["b", "a"]}}

    left = %Contract{
      design_document_identity: @identity,
      bindings: [base],
      provenance: %{"items" => [1, 2]}
    }

    reversed_provenance = %{left | provenance: %{"items" => [2, 1]}}

    assert {:ok, left_digest} = Serializer.digest(left)
    assert {:ok, provenance_digest} = Serializer.digest(reversed_provenance)

    assert {:ok, policy_digest} =
             Serializer.digest(%{left | bindings: [reverse_policy]})

    refute left_digest == provenance_digest
    refute left_digest == policy_digest
  end

  test "canonicalizes map insertion order without hiding digest-significant changes" do
    left_binding =
      persisted_binding("a", 0,
        initial_state: %{"a" => 1, "b" => 2},
        primitive_policy_values: %{"nested" => %{"a" => 1, "b" => 2}},
        provenance: %{"first" => true, "second" => [1, 2]}
      )

    reordered_maps =
      persisted_binding("a", 0,
        initial_state: %{"b" => 2, "a" => 1},
        primitive_policy_values: %{"nested" => %{"b" => 2, "a" => 1}},
        provenance: %{"second" => [1, 2], "first" => true}
      )

    contract = %Contract{
      design_document_identity: @identity,
      bindings: [left_binding],
      provenance: %{"a" => %{"x" => true, "y" => false}}
    }

    assert {:ok, bytes} = Serializer.encode(contract)

    assert {:ok, ^bytes} =
             Serializer.encode(%{
               contract
               | bindings: [reordered_maps],
                 provenance: %{"a" => %{"y" => false, "x" => true}}
             })
  end

  test "includes PrimitiveRef version, binding provenance, SourceTrace, and diagnostics in digest" do
    binding = persisted_binding("a", 0, provenance: %{"source" => "original"})
    base = %Contract{design_document_identity: @identity, bindings: [binding]}

    changed_definition = %{
      base
      | bindings: [
          %{binding | primitive_ref: %{binding.primitive_ref | definition_version: "2.0.0"}}
        ]
    }

    changed_provenance = %{base | bindings: [%{binding | provenance: %{"source" => "changed"}}]}

    changed_trace = %{
      base
      | bindings: [%{binding | source_trace: %SourceTrace{source_id: "changed"}}]
    }

    changed_diagnostic = %{
      base
      | bindings: [
          %{
            binding
            | diagnostics: [
                %Diagnostic{
                  code: "behavior.note",
                  severity: "info",
                  category: "structure",
                  message: "changed"
                }
              ]
          }
        ]
    }

    assert {:ok, base_digest} = Serializer.digest(base)
    assert {:ok, definition_digest} = Serializer.digest(changed_definition)
    assert {:ok, provenance_digest} = Serializer.digest(changed_provenance)
    assert {:ok, trace_digest} = Serializer.digest(changed_trace)
    assert {:ok, diagnostic_digest} = Serializer.digest(changed_diagnostic)

    refute base_digest == definition_digest
    refute base_digest == provenance_digest
    refute base_digest == trace_digest
    refute base_digest == diagnostic_digest
  end

  test "serializes all diagnostic fields and sorts diagnostics independent of list order" do
    first = %Diagnostic{
      code: "behavior.a",
      severity: "warning",
      category: "structure",
      binding_id: nil,
      node_id: "node-a",
      evidence_id: "evidence-a",
      message: "First",
      suggested_action: nil,
      source_trace: nil
    }

    second = %{first | code: "behavior.z", message: "Second", suggested_action: "Review"}

    assert {:ok, bytes} =
             Serializer.encode(%Contract{
               design_document_identity: @identity,
               diagnostics: [second, first, first]
             })

    assert {:ok, ^bytes} =
             Serializer.encode(%Contract{
               design_document_identity: @identity,
               diagnostics: [first, second, first]
             })

    [encoded_first, encoded_duplicate, encoded_second] =
      bytes |> Jason.decode!() |> Map.fetch!("diagnostics")

    assert encoded_first["code"] == "behavior.a"
    assert encoded_duplicate == encoded_first
    assert encoded_second["suggested_action"] == "Review"

    assert Map.keys(encoded_first) |> Enum.sort() ==
             ~w(binding_id category code evidence_id message node_id severity source_trace suggested_action)
  end

  test "uses complete diagnostic canonical bytes to break primary-key ties" do
    base = %Diagnostic{
      code: "behavior.same",
      severity: "warning",
      category: "provenance",
      message: "Same primary tuple"
    }

    first = %{base | suggested_action: "alpha"}
    second = %{base | suggested_action: "zeta"}

    assert {:ok, bytes} =
             Serializer.encode(%Contract{
               design_document_identity: @identity,
               diagnostics: [second, first]
             })

    assert {:ok, ^bytes} =
             Serializer.encode(%Contract{
               design_document_identity: @identity,
               diagnostics: [first, second]
             })

    assert Enum.map(Jason.decode!(bytes)["diagnostics"], & &1["suggested_action"]) == [
             "alpha",
             "zeta"
           ]
  end

  test "rejects binding-owned diagnostic binding IDs even when they name the container" do
    binding = persisted_binding("a", 0)

    diagnostic = %Diagnostic{
      code: "behavior.issue",
      severity: "error",
      category: "structure",
      binding_id: binding.binding_id,
      message: "Issue"
    }

    assert {:error, [%{code: "behavior.diagnostic.invalid", category: "structure"}]} =
             Serializer.encode(%Contract{
               design_document_identity: @identity,
               bindings: [%{binding | diagnostics: [diagnostic]}]
             })
  end

  test "rejects contract diagnostics with an unresolved binding ID" do
    diagnostic = %Diagnostic{
      code: "behavior.issue",
      severity: "error",
      category: "structure",
      binding_id: "bnd_" <> String.duplicate("f", 64),
      message: "Issue"
    }

    assert {:error, [%{code: "behavior.diagnostic.binding_unresolved", category: "reference"}]} =
             Serializer.encode(%Contract{
               design_document_identity: @identity,
               diagnostics: [diagnostic]
             })
  end

  test "rejects diagnostic values outside the exact safe vocabularies" do
    binding_id = "bnd_" <> String.duplicate("a", 64)

    invalid_diagnostics = [
      %Diagnostic{code: "", severity: "error", category: "structure", message: "x"},
      %Diagnostic{code: "x", severity: "ERROR", category: "structure", message: "x"},
      %Diagnostic{code: "x", severity: "error", category: "unknown", message: "x"},
      %Diagnostic{
        code: "x",
        severity: "error",
        category: "structure",
        evidence_id: "",
        message: "x"
      },
      %Diagnostic{
        code: "x",
        severity: "error",
        category: "structure",
        binding_id: "bad-id",
        message: "x"
      },
      %Diagnostic{code: "x", severity: "error", category: "structure", message: <<0xFF>>}
    ]

    for diagnostic <- invalid_diagnostics do
      assert {:error, [%{code: "behavior.diagnostic.invalid", category: "structure"}]} =
               Serializer.encode(%Contract{
                 design_document_identity: @identity,
                 bindings: [persisted_binding("a", 0)],
                 diagnostics: [diagnostic]
               })
    end

    assert {:ok, _bytes} =
             Serializer.encode(%Contract{
               design_document_identity: @identity,
               bindings: [persisted_binding("a", 0)],
               diagnostics: [
                 %Diagnostic{
                   code: "x",
                   severity: "error",
                   category: "structure",
                   binding_id: binding_id,
                   message: "x"
                 }
               ]
             })
  end

  test "rejects contract and binding provenance outside the canonical object algebra" do
    assert {:error, [%{code: "behavior.provenance.invalid", category: "provenance"}]} =
             Serializer.encode(%Contract{
               design_document_identity: @identity,
               provenance: %{atom_key: "not allowed"}
             })

    binding = persisted_binding("a", 0, provenance: %{"unsafe" => fn -> :value end})

    assert {:error, [%{code: "behavior.provenance.invalid", category: "provenance"}]} =
             Serializer.encode(%Contract{
               design_document_identity: @identity,
               bindings: [binding]
             })
  end

  test "matches the frozen complete BehaviorContract canonical bytes" do
    expected =
      ~S|{"behavior_contract_format_version":"1.0.0","bindings":[{"binding_id":"bnd_bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb","binding_role":"main","controlled_targets":[{"node_id":"node-panel","role":"content"}],"diagnostics":[{"binding_id":null,"category":"provenance","code":"behavior.binding.note","evidence_id":"opaque-evidence","message":"Binding evidence retained","node_id":"node-external","severity":"warning","source_trace":null,"suggested_action":null}],"focus_policy":{"containment_strategy":"trap","initial_strategy":"first_available","initial_target_node_id":"node-initial","movement_strategy":"linear","restoration_fallback_node_id":"node-fallback","restoration_strategy":"target","restoration_target_node_id":"node-restore","scope_node_id":null},"initial_state":{"open":false},"keyboard_policy":{"keys":["Enter","Space"]},"motion_policy":{"reduced_motion":"respect"},"ordinal":0,"owner_node_id":"node-owner","primitive_policy_values":{"ordered":["second","first"],"threshold":2},"primitive_ref":{"definition_version":"9.9.9","kind":"unknown-kind"},"provenance":{"source_events":["observed","normalized"]},"responsive_overrides":[{"authority_ref":"responsive-authority","mode":"compact","state_mapping":{"open":false}}],"source_trace":{"adapter":"adapter","adapter_version":"1","inference":"observed","metadata":{"evidence":"opaque"},"source_classes":["alpha","zeta"],"source_id":"source-1","source_name":"Hero","source_path":"inert/source/path","source_settings":{"sequence":["second","first"]},"source_type":"builder"},"timer_policy":{"delay":300,"enabled":true},"triggers":[{"kind":"activate","origin_node_id":"node-trigger"}]}],"design_document_identity":{"canonicalization_id":"lf-ir-serializer-v1","digest":"0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef","digest_algorithm":"sha-256","ir_version":"3.0.0"},"diagnostics":[{"binding_id":"bnd_bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb","category":"provenance","code":"behavior.contract.note","evidence_id":"contract-evidence","message":"Contract evidence retained","node_id":"node-contract","severity":"warning","source_trace":null,"suggested_action":"Review"}],"provenance":{"contract_events":["captured","normalized"]}}|

    assert {:ok, ^expected} = Serializer.encode(golden_contract())
  end

  test "matches the independently frozen SHA-256 digest" do
    assert {:ok, "c4c4b3aef43a443bd7b8f233889b10d3f73504bc9fd10f25ea5a824e9720650c"} =
             Serializer.digest(golden_contract())
  end

  defp persisted_binding(suffix, ordinal, attrs \\ []) do
    %Binding{
      binding_id: "bnd_" <> String.duplicate(suffix, 64),
      ordinal: ordinal,
      primitive_ref: %PrimitiveRef{kind: "disclosure", definition_version: "1.0.0"},
      owner_node_id: "node-owner",
      binding_role: "primary"
    }
    |> struct(attrs)
  end

  defp trigger(kind, origin), do: %Trigger{kind: kind, origin_node_id: origin}
  defp target(role, node_id), do: %ControlledTarget{role: role, node_id: node_id}

  defp override(mode) do
    %ResponsiveBehaviorOverride{mode: mode, authority_ref: nil, state_mapping: %{}}
  end

  defp override(mode, authority_ref, state_mapping) do
    %ResponsiveBehaviorOverride{
      mode: mode,
      authority_ref: authority_ref,
      state_mapping: state_mapping
    }
  end

  defp golden_contract do
    binding_id = "bnd_" <> String.duplicate("b", 64)

    binding = %Binding{
      binding_id: binding_id,
      ordinal: 0,
      primitive_ref: %PrimitiveRef{kind: "unknown-kind", definition_version: "9.9.9"},
      owner_node_id: "node-owner",
      binding_role: "main",
      initial_state: %{"open" => false},
      primitive_policy_values: %{"ordered" => ["second", "first"], "threshold" => 2},
      triggers: [%Trigger{kind: "activate", origin_node_id: "node-trigger"}],
      controlled_targets: [%ControlledTarget{role: "content", node_id: "node-panel"}],
      timer_policy: %{"delay" => 300, "enabled" => true},
      focus_policy: %FocusPolicy{
        initial_strategy: "first_available",
        initial_target_node_id: "node-initial",
        containment_strategy: "trap",
        movement_strategy: "linear",
        scope_node_id: nil,
        restoration_strategy: "target",
        restoration_target_node_id: "node-restore",
        restoration_fallback_node_id: "node-fallback"
      },
      keyboard_policy: %{"keys" => ["Enter", "Space"]},
      motion_policy: %{"reduced_motion" => "respect"},
      responsive_overrides: [override("compact", "responsive-authority", %{"open" => false})],
      diagnostics: [
        %Diagnostic{
          code: "behavior.binding.note",
          severity: "warning",
          category: "provenance",
          node_id: "node-external",
          evidence_id: "opaque-evidence",
          message: "Binding evidence retained"
        }
      ],
      provenance: %{"source_events" => ["observed", "normalized"]},
      source_trace: %SourceTrace{
        source_type: "builder",
        source_id: "source-1",
        source_path: "inert/source/path",
        source_name: "Hero",
        source_classes: ["zeta", "alpha"],
        source_settings: %{"sequence" => ["second", "first"]},
        adapter: "adapter",
        adapter_version: "1",
        inference: "observed",
        metadata: %{"evidence" => "opaque"}
      }
    }

    %Contract{
      design_document_identity: %Identity{
        ir_version: "3.0.0",
        canonicalization_id: "lf-ir-serializer-v1",
        digest_algorithm: "sha-256",
        digest: "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef"
      },
      bindings: [binding],
      diagnostics: [
        %Diagnostic{
          code: "behavior.contract.note",
          severity: "warning",
          category: "provenance",
          binding_id: binding_id,
          node_id: "node-contract",
          evidence_id: "contract-evidence",
          message: "Contract evidence retained",
          suggested_action: "Review"
        }
      ],
      provenance: %{"contract_events" => ["captured", "normalized"]}
    }
  end
end
