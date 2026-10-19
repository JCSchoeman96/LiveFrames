defmodule LiveFrames.BricksSourceLocalCustomPropertyResolverTest do
  use ExUnit.Case, async: true

  alias LiveFrames.Adapters.Bricks.SourceLocalCustomPropertyResolver
  alias LiveFrames.Fidelity.CSSDeclaration

  @owner_source_id "owner"
  @effective_provenance_identity {"owner", :global_class, "class-a", :local, ["auth-a"], 0}

  defp definition(local_name, terminal_text, target_path, opts \\ []) do
    Map.merge(
      %{
        owner_source_id: @owner_source_id,
        effective_provenance_identity: @effective_provenance_identity,
        target_source_id: "definition-#{inspect(target_path)}",
        target_path: target_path,
        selector_identity: :selector_a,
        viewport_scope: :base,
        state_scope: nil,
        source_order: 0,
        local_name: local_name,
        record_kind: :definition,
        terminal_text: terminal_text
      },
      Map.new(opts)
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
        source_order: 0,
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
      authority_index: %{}
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
end
