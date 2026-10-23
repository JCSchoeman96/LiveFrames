defmodule LiveFrames.BricksSourceLocalCustomPropertyResolverTest do
  use ExUnit.Case, async: true

  alias LiveFrames.Adapters.Bricks.SourceLocalCustomPropertyResolver
  alias LiveFrames.Fidelity.CSSDeclaration
  alias LiveFrames.Tokens.VariableAuthority

  @owner_source_id "owner"
  @effective_provenance_identity {"owner", :global_class, "class-a", :local, ["auth-a"], 0}

  defp definition(local_name, terminal_text, target_path, opts \\ []) do
    opts = Map.new(opts)
    frame_source_order = Map.get(opts, :source_order, 0)
    opts = opts |> Map.delete(:source_order) |> Map.put(:source_order, {0, frame_source_order})

    Map.merge(
      %{
        owner_source_id: @owner_source_id,
        effective_provenance_identity: @effective_provenance_identity,
        target_source_id: "definition-#{inspect(target_path)}",
        target_path: target_path,
        selector_identity: :selector_a,
        viewport_scope: :base,
        state_scope: nil,
        source_order: {0, 0},
        local_name: local_name,
        record_kind: :definition,
        terminal_text_if_definition: terminal_text
      },
      opts
    )
  end

  defp reference(local_name, target_path, opts \\ []) do
    Map.merge(
      %{
        owner_source_id: @owner_source_id,
        effective_provenance_identity: @effective_provenance_identity,
        target_source_id: "reference-#{inspect(target_path)}",
        target_path: target_path,
        selector_identity: :selector_reference,
        viewport_scope: :base,
        state_scope: nil,
        source_order: {0, 0},
        local_name: local_name,
        record_kind: :reference
      },
      Map.new(opts)
    )
  end

  defp batch_opts(
         owner_source_id \\ @owner_source_id,
         effective_provenance_identity \\ @effective_provenance_identity
       ) do
    [
      owner_source_id: owner_source_id,
      effective_provenance_identity: effective_provenance_identity,
      authority_index: %VariableAuthority{}
    ]
  end

  defp resolve(definitions, references, opts \\ []) do
    SourceLocalCustomPropertyResolver.resolve(
      definitions,
      references,
      Keyword.merge(batch_opts(), opts)
    )
  end

  test "validates exact local names with the existing property boundary" do
    assert CSSDeclaration.safe_property?("--local-name")
    assert CSSDeclaration.safe_property?("color")
    refute CSSDeclaration.safe_property?("--Bad")

    valid_definition = definition("--local-name", "12px", [1])

    assert {:ok, [{:ok, "12px"}]} =
             resolve([valid_definition], [reference("--local-name", [1])])

    for invalid_name <- ["color", "--Bad"] do
      assert {:ok, [{:error, :invalid_local_name}]} =
               resolve([valid_definition], [reference(invalid_name, [1])])
    end
  end

  test "isolates definitions by exact effective provenance" do
    reference_record = reference("--local-name", [1])

    mismatched_provenances = [
      {"other-owner", :global_class, "class-a", :local, ["auth-a"], 0},
      {"owner", :element_local, nil, nil, [], nil},
      {"owner", :global_class, "class-b", :local, ["auth-a"], 0},
      {"owner", :global_class, "class-a", :external, ["auth-a"], 0},
      {"owner", :global_class, "class-a", :local, ["auth-b", "auth-a"], 0},
      {"owner", :global_class, "class-a", :local, ["auth-a"], 1}
    ]

    for provenance_identity <- mismatched_provenances do
      definition_record =
        definition("--local-name", "12px", [1],
          effective_provenance_identity: provenance_identity
        )

      assert {:ok, [{:error, :no_local_definition}]} =
               resolve([definition_record], [reference_record])
    end
  end

  test "rejects foreign owner records supplied to one owner batch" do
    definition_record =
      definition("--local-name", "12px", [1], owner_source_id: "another-owner")

    references = [reference("--local-name", [1]), reference("--other", [1])]

    assert {:ok, [{:error, :cross_owner_reference}, {:error, :cross_owner_reference}]} =
             resolve([definition_record], references)
  end

  test "prefers a direct target definition over every ancestor" do
    definitions = [
      definition("--local-name", "ancestor", [1]),
      definition("--local-name", "farther", [1, 2]),
      definition("--local-name", "direct", [1, 2, 3])
    ]

    assert {:ok, [{:ok, "direct"}]} =
             resolve(definitions, [reference("--local-name", [1, 2, 3])])
  end

  test "selects only the nearest proven ancestor" do
    definitions = [
      definition("--local-name", "farther", [1]),
      definition("--local-name", "nearest", [1, 2]),
      definition("--local-name", "sibling", [1, 3])
    ]

    assert {:ok, [{:ok, "nearest"}]} =
             resolve(definitions, [reference("--local-name", [1, 2, 4])])
  end

  test "coalesces byte-identical definitions with one selector identity" do
    definitions = [
      definition("--local-name", "12px", [1], source_order: 1),
      definition("--local-name", "12px", [1], source_order: 2)
    ]

    assert {:ok, [{:ok, "12px"}]} =
             resolve(definitions, [reference("--local-name", [1])])
  end

  test "rejects conflicting same-identity definitions without source-order selection" do
    earlier = definition("--local-name", "12px", [1], source_order: 1)
    later = definition("--local-name", "14px", [1], source_order: 2)
    reference_record = reference("--local-name", [1])

    for definitions <- [[earlier, later], [later, earlier]] do
      assert {:ok, [{:error, :conflicting_source_order}]} =
               resolve(definitions, [reference_record])
    end
  end

  test "keeps different selector identities ambiguous when terminals match" do
    definitions = [
      definition("--local-name", "12px", [1], selector_identity: :selector_a),
      definition("--local-name", "12px", [1], selector_identity: :selector_b)
    ]

    assert {:ok, [{:error, :ambiguous_definition}]} =
             resolve(definitions, [reference("--local-name", [1])])
  end

  test "preserves reference result order and cardinality" do
    definitions = [
      definition("--first", "one", [1]),
      definition("--second", "two", [1])
    ]

    references = [
      reference("--second", [1]),
      reference("--missing", [1]),
      reference("--first", [1])
    ]

    assert {:ok, [{:ok, "two"}, {:error, :no_local_definition}, {:ok, "one"}]} =
             resolve(definitions, references)
  end

  test "does not treat var text inside a quoted terminal as a dependency" do
    nbsp = <<0xC2, 0xA0>>
    quoted_terminals = ["\"var(--hidden)\"", "\"var(#{nbsp}--hidden)\""]

    for quoted_terminal <- quoted_terminals do
      assert {:ok, [{:ok, ^quoted_terminal}]} =
               resolve(
                 [definition("--local-name", quoted_terminal, [1])],
                 [reference("--local-name", [1])]
               )
    end
  end

  test "fails closed on an escaped var function spelling" do
    escaped_var_terminal = "v\\61 r(--hidden)"

    assert {:ok, [{:error, :unsupported_nested_reference}]} =
             resolve(
               [definition("--local-name", escaped_var_terminal, [1])],
               [reference("--local-name", [1])]
             )
  end

  test "counts dependency edges after identical definitions coalesce" do
    terminal = String.duplicate("var(--a)", 350)

    definitions =
      for source_order <- 1..3 do
        definition("--local-name", terminal, [1], source_order: source_order)
      end

    assert {:ok, [{:error, :unsupported_nested_reference}]} =
             resolve(definitions, [reference("--local-name", [1])])
  end

  test "labels only cyclic definitions as cycles" do
    definitions = [
      definition("--root", "var(--a)", [1]),
      definition("--a", "var(--b)", [1]),
      definition("--b", "var(--a)", [1])
    ]

    references = [reference("--root", [1]), reference("--a", [1])]

    assert {:ok, [{:error, :cycle}, {:error, :cycle}]} = resolve(definitions, references)
  end

  test "allows exactly 256 definitions and rejects 257 at batch level" do
    definitions =
      for source_order <- 1..256 do
        definition("--local-name", "12px", [1], source_order: source_order)
      end

    references = [reference("--local-name", [1])]

    assert {:ok, [{:ok, "12px"}]} = resolve(definitions, references)

    assert {:error, :resource_limit_exceeded} =
             resolve(definitions ++ [definition("--local-name", "12px", [1])], references)
  end

  test "allows exactly 1024 references and rejects 1025 at batch level" do
    definitions = [definition("--local-name", "12px", [1])]
    references = for _index <- 1..1024, do: reference("--local-name", [1])

    assert {:ok, results} = resolve(definitions, references)
    assert length(results) == 1024
    assert Enum.all?(results, &(&1 == {:ok, "12px"}))

    assert {:error, :resource_limit_exceeded} =
             resolve(definitions, references ++ [reference("--local-name", [1])])
  end

  test "resolves the maximum candidate group across the maximum reference batch" do
    definitions =
      for source_order <- 1..256 do
        definition("--local-name", "12px", [1], source_order: source_order)
      end

    references = for _index <- 1..1024, do: reference("--local-name", [1])

    assert {:ok, results} = resolve(definitions, references)
    assert length(results) == 1024
    assert Enum.all?(results, &(&1 == {:ok, "12px"}))
  end

  test "allows long absolute paths while enforcing relative ancestry distance" do
    target_path = Enum.to_list(1..2_000)
    depth_64_ancestor = Enum.take(target_path, 2_000 - 64)
    definitions = [definition("--local-name", "12px", depth_64_ancestor)]
    references = for _index <- 1..1_024, do: reference("--local-name", target_path)

    assert {:ok, results} = resolve(definitions, references)

    assert length(results) == 1_024
    assert Enum.all?(results, &(&1 == {:ok, "12px"}))
  end

  test "rejects terminal text above 4096 bytes" do
    terminal_at_limit = String.duplicate("x", 4096)
    definition_record = definition("--local-name", String.duplicate("x", 4097), [1])

    assert {:ok, [{:ok, ^terminal_at_limit}]} =
             resolve([definition("--local-name", terminal_at_limit, [1])], [
               reference("--local-name", [1])
             ])

    assert {:ok, [{:error, :resource_limit_exceeded}]} =
             resolve([definition_record], [reference("--local-name", [1])])
  end

  test "rejects an oversized terminal before comparing duplicate candidates" do
    definitions = [
      definition("--local-name", String.duplicate("x", 4097), [1]),
      definition("--local-name", "12px", [1])
    ]

    assert {:ok, [{:error, :resource_limit_exceeded}]} =
             resolve(definitions, [reference("--local-name", [1])])
  end

  test "limits relative ancestry distance rather than absolute path length" do
    long_ancestor = Enum.to_list(1..100)
    adjacent_descendant = Enum.to_list(1..101)

    assert {:ok, [{:ok, "near"}]} =
             resolve(
               [definition("--local-name", "near", long_ancestor)],
               [reference("--local-name", adjacent_descendant)]
             )

    depth_64_ancestor = Enum.to_list(1..36)
    depth_64_descendant = Enum.to_list(1..100)

    assert {:ok, [{:ok, "depth-64"}]} =
             resolve(
               [definition("--local-name", "depth-64", depth_64_ancestor)],
               [reference("--local-name", depth_64_descendant)]
             )

    depth_65_ancestor = Enum.to_list(1..35)

    assert {:ok, [{:error, :resource_limit_exceeded}]} =
             resolve(
               [definition("--local-name", "depth-65", depth_65_ancestor)],
               [reference("--local-name", depth_64_descendant)]
             )
  end

  test "allows base definitions for responsive references at the target or nearest ancestor" do
    responsive_scope = {:responsive_source_key, "tablet-source"}

    cases = [
      {[1, 2], [1, 2]},
      {[1], [1, 2]}
    ]

    for {definition_path, reference_path} <- cases do
      assert {:ok, [{:ok, "12px"}]} =
               resolve(
                 [definition("--local-name", "12px", definition_path)],
                 [reference("--local-name", reference_path, viewport_scope: responsive_scope)]
               )
    end
  end

  test "same-target responsive definition blocks base fallback" do
    responsive_scope = {:responsive_source_key, "tablet-source"}

    definitions = [
      definition("--local-name", "12px", [1]),
      definition("--local-name", "var(--nested-name)", [1], viewport_scope: responsive_scope)
    ]

    assert {:ok, [{:error, :unsupported_scope}]} =
             resolve(definitions, [
               reference("--local-name", [1], viewport_scope: responsive_scope)
             ])
  end

  test "nearest responsive ancestor blocks base fallback" do
    responsive_scope = {:responsive_source_key, "tablet-source"}

    definitions = [
      definition("--local-name", "12px", [1]),
      definition("--local-name", "var(--nested-name)", [1], viewport_scope: responsive_scope)
    ]

    assert {:ok, [{:error, :unsupported_scope}]} =
             resolve(definitions, [
               reference("--local-name", [1, 2], viewport_scope: responsive_scope)
             ])
  end

  test "direct base definition takes precedence over a nearest responsive ancestor" do
    responsive_scope = {:responsive_source_key, "tablet-source"}

    definitions = [
      definition("--local-name", "12px", [1, 2]),
      definition("--local-name", "18px", [1], viewport_scope: responsive_scope)
    ]

    assert {:ok, [{:ok, "12px"}]} =
             resolve(definitions, [
               reference("--local-name", [1, 2], viewport_scope: responsive_scope)
             ])
  end

  test "rejects state-scoped lookups and responsive-only resolution" do
    assert {:ok, [{:error, :unsupported_scope}]} =
             resolve(
               [definition("--local-name", "12px", [1])],
               [reference("--local-name", [1], state_scope: :hover)]
             )

    responsive_scope = {:responsive_source_key, "tablet-source"}

    assert {:ok, [{:error, :unsupported_scope}]} =
             resolve(
               [definition("--local-name", "12px", [1], viewport_scope: responsive_scope)],
               [reference("--local-name", [1], viewport_scope: responsive_scope)]
             )
  end

  test "does not resolve sibling paths or other responsive source keys" do
    assert {:ok, [{:error, :no_local_definition}]} =
             resolve(
               [definition("--local-name", "12px", [1, 2])],
               [reference("--local-name", [1, 3])]
             )

    assert {:ok, [{:ok, "12px"}]} =
             resolve(
               [
                 definition("--local-name", "12px", [1]),
                 definition("--local-name", "var(--other)", [1],
                   viewport_scope: {:responsive_source_key, "other-source"}
                 )
               ],
               [
                 reference("--local-name", [1],
                   viewport_scope: {:responsive_source_key, "tablet-source"}
                 )
               ]
             )
  end

  test "rejects an external authority collision without substituting its candidate" do
    authority_index = %VariableAuthority{
      by_variable: %{"--local-name" => %{"secret-token-path" => [%{"source" => "external"}]}}
    }

    assert {:ok, [{:error, :external_authority_collision}]} =
             resolve(
               [definition("--local-name", "12px", [1])],
               [reference("--local-name", [1])],
               authority_index: authority_index
             )
  end

  test "checks external collision by exact-name presence without resolving candidates" do
    authority_index = %VariableAuthority{by_variable: %{"--local-name" => %{}}}

    assert {:ok, [{:error, :external_authority_collision}]} =
             resolve(
               [definition("--local-name", "12px", [1])],
               [reference("--local-name", [1])],
               authority_index: authority_index
             )
  end

  test "classifies definition compiler-input terminals with the shared dependency scanner" do
    assert :ok =
             SourceLocalCustomPropertyResolver.definition_compiler_input_state(
               "--local-name",
               "12px"
             )

    assert :ok =
             SourceLocalCustomPropertyResolver.definition_compiler_input_state(
               "--local-name",
               "var(--nested-name)"
             )

    assert {:error, :unsupported_fallback} =
             SourceLocalCustomPropertyResolver.definition_compiler_input_state(
               "--local-name",
               "var(--nested-name, 4px)"
             )

    assert {:error, :self_reference} =
             SourceLocalCustomPropertyResolver.definition_compiler_input_state(
               "--local-name",
               "var(--local-name)"
             )

    assert {:error, :unsupported_nested_reference} =
             SourceLocalCustomPropertyResolver.definition_compiler_input_state(
               "--local-name",
               "var(color)"
             )
  end

  test "admits only an exact single-var passthrough compiler input" do
    assert :ok =
             SourceLocalCustomPropertyResolver.definition_compiler_input_state("--a", "var(--b)")

    for terminal <- ["12px", "0.5", "auto"] do
      assert :ok =
               SourceLocalCustomPropertyResolver.definition_compiler_input_state(
                 "--local-name",
                 terminal
               )
    end

    assert {:error, :unsupported_fallback} =
             SourceLocalCustomPropertyResolver.definition_compiler_input_state(
               "--local-name",
               "var(--b, 4px)"
             )

    assert {:error, :self_reference} =
             SourceLocalCustomPropertyResolver.definition_compiler_input_state(
               "--local-name",
               "var(--local-name)"
             )
  end

  test "uses only the five CSS whitespace bytes in passthrough syntax" do
    whitespace_bytes = [" ", "\t", "\n", "\r", "\f"]

    for whitespace <- whitespace_bytes,
        terminal <- [
          whitespace <> "var(--b)",
          "var(" <> whitespace <> "--b)",
          "var(--b" <> whitespace <> ")",
          "var(--b)" <> whitespace
        ] do
      assert :ok =
               SourceLocalCustomPropertyResolver.definition_compiler_input_state(
                 "--a",
                 terminal
               )
    end

    assert :ok =
             SourceLocalCustomPropertyResolver.definition_compiler_input_state(
               "--a",
               " \tvar(\n\f--b\r )\t "
             )

    nbsp = <<0xC2, 0xA0>>

    for terminal <- [
          nbsp <> "var(--b)",
          "var(" <> nbsp <> "--b)",
          "var(--b" <> nbsp <> ")",
          "var(--b)" <> nbsp
        ] do
      assert {:error, :unsupported_nested_reference} =
               SourceLocalCustomPropertyResolver.definition_compiler_input_state(
                 "--a",
                 terminal
               )
    end
  end

  test "rejects non-exact passthrough compiler inputs" do
    unsupported_terminals = [
      "/* comment */ var(--b)",
      "prefix var(--b)",
      "var(--b) suffix",
      "calc(var(--b))",
      "var(--b) var(--c)",
      "VAR(--b)",
      "VaR(--b)",
      "v\\61 r(--b)",
      "var(--escaped\\2dname)"
    ]

    for terminal <- unsupported_terminals do
      assert {:error, :unsupported_nested_reference} =
               SourceLocalCustomPropertyResolver.definition_compiler_input_state(
                 "--a",
                 terminal
               ),
             inspect(terminal)
    end
  end

  test "preserves compiler-input name and byte boundaries" do
    assert {:error, :invalid_local_name} =
             SourceLocalCustomPropertyResolver.definition_compiler_input_state("color", "12px")

    for terminal <- ["var(color)", "var(--bad name)"] do
      assert {:error, :unsupported_nested_reference} =
               SourceLocalCustomPropertyResolver.definition_compiler_input_state(
                 "--a",
                 terminal
               )
    end

    terminal_at_limit = String.duplicate("x", 4096)
    terminal_over_limit = String.duplicate("x", 4097)

    assert :ok =
             SourceLocalCustomPropertyResolver.definition_compiler_input_state(
               "--a",
               terminal_at_limit
             )

    assert {:error, :resource_limit_exceeded} =
             SourceLocalCustomPropertyResolver.definition_compiler_input_state(
               "--a",
               terminal_over_limit
             )
  end

  test "classifies fallback and downstream references without substitution" do
    assert {:ok, [{:error, :unsupported_fallback}]} =
             resolve(
               [definition("--local-name", "var(--nested-name, 4px)", [1])],
               [reference("--local-name", [1])]
             )

    assert {:ok, [{:error, :no_local_definition}]} =
             resolve(
               [definition("--local-name", "var(--nested-name)", [1])],
               [reference("--local-name", [1])]
             )
  end

  test "classifies self references and bounded multi-definition cycles" do
    assert {:ok, [{:error, :self_reference}]} =
             resolve(
               [definition("--local-name", "var(--local-name)", [1])],
               [reference("--local-name", [1])]
             )

    cycle_definitions = [
      definition("--first", "var(--second)", [1]),
      definition("--second", "var(--first)", [1])
    ]

    assert {:ok, [{:error, :cycle}]} =
             resolve(cycle_definitions, [reference("--first", [1])])
  end

  test "rejects dependency graphs above 1024 edges at batch level" do
    definitions =
      for index <- 1..3 do
        dependencies = Enum.map_join(1..350, " ", fn _ -> "var(--x)" end)
        definition("--source-#{index}", dependencies, [index])
      end

    assert {:error, :resource_limit_exceeded} =
             resolve(definitions, [reference("--source-1", [1])])
  end

  test "allows exactly 1024 dependency edges" do
    edge_counts = [341, 341, 342]

    definitions =
      edge_counts
      |> Enum.with_index(1)
      |> Enum.map(fn {edge_count, index} ->
        dependencies = Enum.map_join(1..edge_count, " ", fn _ -> "var(--x)" end)
        definition("--source-#{index}", dependencies, [index])
      end)

    assert {:ok, [{:error, :unsupported_nested_reference}]} =
             resolve(definitions, [reference("--source-1", [1])])
  end

  test "returns no local definition for an ordinary miss" do
    assert {:ok, [{:error, :no_local_definition}]} =
             resolve([], [reference("--missing", [1])])
  end

  test "resolves an exact passthrough to a same-path base terminal" do
    definitions = [
      definition("--b", "12px", [1]),
      definition("--a", "var(--b)", [1])
    ]

    assert {:ok, [{:ok, "12px"}]} =
             resolve(definitions, [reference("--a", [1])])
  end

  test "rejects a second dependency hop without expanding it" do
    definitions = [
      definition("--c", "12px", [1]),
      definition("--b", "var(--c)", [1]),
      definition("--a", "var(--b)", [1])
    ]

    assert {:ok, [{:error, :unsupported_nested_reference}]} =
             resolve(definitions, [reference("--a", [1])])
  end

  test "selects the nearest base ancestor for a passthrough dependency" do
    definitions = [
      definition("--b", "ancestor", [1]),
      definition("--b", "direct", [1, 2]),
      definition("--a", "var(--b)", [1, 2, 3])
    ]

    assert {:ok, [{:ok, "direct"}]} =
             resolve(definitions, [reference("--a", [1, 2, 3])])
  end

  test "same-path dependency wins over an eligible ancestor" do
    definitions = [
      definition("--b", "ancestor", [1]),
      definition("--b", "same-path", [1, 2, 3]),
      definition("--a", "var(--b)", [1, 2, 3])
    ]

    assert {:ok, [{:ok, "same-path"}]} =
             resolve(definitions, [reference("--a", [1, 2, 3])])
  end

  test "keeps nested dependency failures within the existing closed taxonomy" do
    cases = [
      {[definition("--a", "var(--a)", [1])], :self_reference},
      {[
         definition("--a", "var(--b)", [1]),
         definition("--b", "var(--a)", [1])
       ], :cycle},
      {[definition("--a", "var(--b, 4px)", [1])], :unsupported_fallback},
      {[definition("--a", "var(--missing)", [1])], :no_local_definition}
    ]

    for {definitions, expected} <- cases do
      assert {:ok, [{:error, ^expected}]} =
               resolve(definitions, [reference("--a", [1])])
    end
  end

  test "keeps ineligible nested dependency definitions out of the base lookup" do
    responsive_scope = {:responsive_source_key, "tablet-source"}
    other_provenance = {"owner", :global_class, "class-b", :local, ["auth-a"], 0}

    cases = [
      {[definition("--a", "var(--b)", [1])], [1]},
      {[
         definition("--a", "var(--b)", [1, 2]),
         definition("--b", "12px", [1, 3])
       ], [1, 2]},
      {[
         definition("--a", "var(--b)", [1]),
         definition("--b", "12px", [1], effective_provenance_identity: other_provenance)
       ], [1]},
      {[
         definition("--a", "var(--b)", [1]),
         definition("--b", "12px", [1], viewport_scope: responsive_scope)
       ], [1]},
      {[
         definition("--a", "var(--b)", [1]),
         definition("--b", "12px", [1], state_scope: :hover)
       ], [1]}
    ]

    for {definitions, target_path} <- cases do
      assert {:ok, [{:error, :no_local_definition}]} =
               resolve(definitions, [reference("--a", target_path)])
    end
  end

  test "preserves downstream definition failures for a passthrough" do
    cases = [
      {[
         definition("--a", "var(--b)", [1]),
         definition("--b", "var(--c, 4px)", [1])
       ], :unsupported_fallback},
      {[
         definition("--a", "var(--b)", [1]),
         definition("--b", "var(--b)", [1])
       ], :self_reference},
      {[
         definition("--a", "var(--b)", [1]),
         definition("--b", "var(--c)", [1]),
         definition("--c", "var(--b)", [1])
       ], :cycle},
      {[
         definition("--a", "var(--b)", [1]),
         definition("--b", "calc(var(--c))", [1]),
         definition("--c", "12px", [1])
       ], :unsupported_nested_reference}
    ]

    for {definitions, expected} <- cases do
      assert {:ok, [{:error, ^expected}]} =
               resolve(definitions, [reference("--a", [1])])
    end
  end

  test "rejects foreign-owner and malformed-path nested dependency batches" do
    foreign_definitions = [
      definition("--a", "var(--b)", [1]),
      definition("--b", "12px", [1], owner_source_id: "another-owner")
    ]

    assert {:ok, [{:error, :cross_owner_reference}]} =
             resolve(foreign_definitions, [reference("--a", [1])])

    for target_path <- [nil, :malformed] do
      assert {:ok, [{:error, :unsupported_inheritance}]} =
               resolve(
                 [definition("--b", "12px", [1]), definition("--a", "var(--b)", [1])],
                 [reference("--a", target_path)]
               )
    end
  end

  test "preserves ambiguous and conflicting selection outcomes for nested dependencies" do
    ambiguous = [
      definition("--a", "var(--b)", [1]),
      definition("--b", "12px", [1], selector_identity: :selector_a),
      definition("--b", "12px", [1], selector_identity: :selector_b)
    ]

    assert {:ok, [{:error, :ambiguous_definition}]} =
             resolve(ambiguous, [reference("--a", [1])])

    conflicting = [
      definition("--a", "var(--b)", [1]),
      definition("--b", "12px", [1], selector_identity: :selector_b, source_order: 1),
      definition("--b", "14px", [1], selector_identity: :selector_b, source_order: 2)
    ]

    assert {:ok, [{:error, :conflicting_source_order}]} =
             resolve(conflicting, [reference("--a", [1])])
  end

  test "checks external authority collisions on passthrough dependencies" do
    authority_index = %VariableAuthority{by_variable: %{"--b" => %{}}}

    assert {:ok, [{:error, :external_authority_collision}]} =
             resolve(
               [definition("--a", "var(--b)", [1]), definition("--b", "12px", [1])],
               [reference("--a", [1])],
               authority_index: authority_index
             )
  end

  test "responsive-only nested B with an external collision remains missing" do
    authority_index = %VariableAuthority{by_variable: %{"--b" => %{}}}
    path = [11, 22]

    assert {:ok, [{:error, :no_local_definition}]} =
             resolve(
               [
                 definition("--a", "var(--b)", path),
                 definition("--b", "12px", path,
                   viewport_scope: {:responsive_source_key, "tablet-b"}
                 )
               ],
               [reference("--a", path)],
               authority_index: authority_index
             )
  end

  test "sibling-only nested B with an external collision remains missing" do
    authority_index = %VariableAuthority{by_variable: %{"--b" => %{}}}
    a_path = [31, 32]

    assert {:ok, [{:error, :no_local_definition}]} =
             resolve(
               [
                 definition("--a", "var(--b)", a_path),
                 definition("--b", "12px", [31, 33])
               ],
               [reference("--a", a_path)],
               authority_index: authority_index
             )
  end

  test "nested B beyond 64 hops keeps the resource failure with an external collision" do
    authority_index = %VariableAuthority{by_variable: %{"--b" => %{}}}
    a_path = Enum.to_list(401..466)

    assert length(a_path) - 1 == 65

    assert {:ok, [{:error, :resource_limit_exceeded}]} =
             resolve(
               [
                 definition("--a", "var(--b)", a_path),
                 definition("--b", "12px", [401])
               ],
               [reference("--a", a_path)],
               authority_index: authority_index
             )
  end

  test "eligible same-path nested B still checks external collision" do
    authority_index = %VariableAuthority{by_variable: %{"--b" => %{}}}
    path = [51, 52]

    assert {:ok, [{:error, :external_authority_collision}]} =
             resolve(
               [
                 definition("--a", "var(--b)", path),
                 definition("--b", "12px", path)
               ],
               [reference("--a", path)],
               authority_index: authority_index
             )
  end

  test "ambiguous eligible nested B takes precedence over external collision" do
    authority_index = %VariableAuthority{by_variable: %{"--b" => %{}}}
    path = [61, 62]

    assert {:ok, [{:error, :ambiguous_definition}]} =
             resolve(
               [
                 definition("--a", "var(--b)", path),
                 definition("--b", "12px", path, selector_identity: :selector_a),
                 definition("--b", "12px", path, selector_identity: :selector_b)
               ],
               [reference("--a", path)],
               authority_index: authority_index
             )
  end

  test "conflicting eligible nested B takes precedence over external collision" do
    authority_index = %VariableAuthority{by_variable: %{"--b" => %{}}}
    path = [71, 72]

    assert {:ok, [{:error, :conflicting_source_order}]} =
             resolve(
               [
                 definition("--a", "var(--b)", path),
                 definition("--b", "12px", path,
                   selector_identity: :selector_b,
                   source_order: 1
                 ),
                 definition("--b", "14px", path,
                   selector_identity: :selector_b,
                   source_order: 2
                 )
               ],
               [reference("--a", path)],
               authority_index: authority_index
             )
  end

  test "distinguishes 64-hop success from beyond-64 failure with non-palindromic paths" do
    dependency_path = [101]
    target_path_at_64 = Enum.to_list(101..165)

    assert length(target_path_at_64) - length(dependency_path) == 64

    assert {:ok, [{:ok, "12px"}]} =
             resolve(
               [
                 definition("--b", "12px", dependency_path),
                 definition("--a", "var(--b)", target_path_at_64)
               ],
               [reference("--a", target_path_at_64)]
             )

    target_path_at_65 = Enum.to_list(101..166)

    assert length(target_path_at_65) - length(dependency_path) == 65

    assert {:ok, [{:error, :resource_limit_exceeded}]} =
             resolve(
               [
                 definition("--b", "12px", dependency_path),
                 definition("--a", "var(--b)", target_path_at_65)
               ],
               [reference("--a", target_path_at_65)]
             )
  end

  test "enforces terminal byte bounds on the selected passthrough dependency" do
    terminal_at_limit = String.duplicate("x", 4096)
    terminal_over_limit = String.duplicate("x", 4097)

    assert {:ok, [{:ok, ^terminal_at_limit}]} =
             resolve(
               [
                 definition("--a", "var(--b)", [1]),
                 definition("--b", terminal_at_limit, [1])
               ],
               [reference("--a", [1])]
             )

    assert {:ok, [{:error, :resource_limit_exceeded}]} =
             resolve(
               [
                 definition("--a", "var(--b)", [1]),
                 definition("--b", terminal_over_limit, [1])
               ],
               [reference("--a", [1])]
             )
  end

  test "resolves one nested definition across the maximum ordered reference batch" do
    definitions = [
      definition("--a", "var(--b)", [1]),
      definition("--b", "12px", [1]),
      definition("--direct", "8px", [1])
    ]

    references =
      for index <- 1..1024 do
        if rem(index, 2) == 1 do
          reference("--a", [1])
        else
          reference("--direct", [1])
        end
      end

    assert {:ok, results} = resolve(definitions, references)
    assert length(results) == 1024

    expected_results =
      Enum.map(1..1024, fn index ->
        if rem(index, 2) == 1, do: {:ok, "12px"}, else: {:ok, "8px"}
      end)

    assert results == expected_results
  end
end
