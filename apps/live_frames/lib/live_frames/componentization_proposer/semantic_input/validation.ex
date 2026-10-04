defmodule LiveFrames.ComponentizationProposer.SemanticInput.Validation do
  @moduledoc false
  alias LiveFrames.ComponentizationProposer.{Diagnostic, SemanticInput}
  alias SemanticInput.Canonicalization

  alias SemanticInput.{
    ContractIdentityDecision,
    ClassificationDecision,
    BoundaryDecision,
    PublicAttrDecision,
    PublicSlotDecision,
    CollectionAdmissionDecision,
    ItemFieldDecision,
    CollectionCountLinkDecision,
    BindingAssignmentDecision,
    RenderPlacementDecision,
    ImageAccessibilityDecision,
    EvidenceHandlingDecision,
    StaticContentDispositionDecision
  }

  alias LiveFrames.{ComponentContract, ComponentizationPlan}
  alias LiveFrames.ComponentContract.{Attr, Slot, Json}
  alias LiveFrames.IR
  alias LiveFrames.IR.DesignDocument

  @singletons [
    contract_identity: ContractIdentityDecision,
    classification: ClassificationDecision,
    boundary: BoundaryDecision
  ]
  @families [
    public_attrs: PublicAttrDecision,
    public_slots: PublicSlotDecision,
    collection_admissions: CollectionAdmissionDecision,
    item_fields: ItemFieldDecision,
    collection_count_links: CollectionCountLinkDecision,
    binding_assignments: BindingAssignmentDecision,
    render_placements: RenderPlacementDecision,
    image_accessibility: ImageAccessibilityDecision,
    evidence_handling: EvidenceHandlingDecision,
    static_content_dispositions: StaticContentDispositionDecision
  ]
  @assignment_kinds [
    :scalar_attr,
    :collection_attr,
    :collection_item_field_value,
    :collection_item_field_nested_collection,
    :collection_count_attr,
    :collection_count_item_field,
    :slot
  ]
  @target_fields [
    :public_attr_name,
    :public_slot_name,
    :item_field_name,
    :parent_item_field_name,
    :source_collection_binding_id
  ]

  @spec validate(term(), DesignDocument.t()) ::
          {:ok, SemanticInput.t()} | {:error, [Diagnostic.t()]}
  def validate(%SemanticInput{} = input, %DesignDocument{} = document) do
    with :ok <- ir_valid(document),
         [] <- shape_errors(input),
         {:ok, canonical} <- Canonicalization.canonicalize(input) do
      indexes = indexes(canonical, document)

      case relationship_errors(canonical, indexes) do
        [] -> {:ok, canonical}
        errors -> finish(errors)
      end
    else
      {:error, errors} -> finish(errors)
      errors -> finish(errors)
    end
  end

  def validate(_, _),
    do:
      finish([
        diagnostic(:invalid, "input", "Expected a SemanticInput and validated DesignDocument")
      ])

  defp ir_valid(document) do
    case IR.validate(document) do
      :ok ->
        :ok

      {:error, _} ->
        {:error,
         [
           diagnostic(:invalid, "design_document", "DesignDocument failed IR validation")
         ]}
    end
  end

  defp shape_errors(input) do
    root = closed_shape(input, SemanticInput, "input")

    singles =
      Enum.flat_map(@singletons, fn {family, module} ->
        case Map.fetch!(input, family) do
          nil ->
            [
              diagnostic(
                :missing_decision,
                Atom.to_string(family),
                "Singleton decision is required"
              )
            ]

          decision ->
            record_errors(decision, module, family)
        end
      end)

    repeats =
      Enum.flat_map(@families, fn {family, module} ->
        case Map.fetch!(input, family) do
          decisions when is_list(decisions) ->
            Enum.flat_map(decisions, &record_errors(&1, module, family))

          _ ->
            [diagnostic(:invalid, Atom.to_string(family), "Decision family must be a list")]
        end
      end)

    root ++ singles ++ repeats
  end

  # Modules here are fixed by compiled clauses, never supplied by input.
  defp closed_shape(record, module, path) do
    if is_struct(record, module) and
         Map.keys(record) |> MapSet.new() == Map.keys(struct(module)) |> MapSet.new(),
       do: [],
       else: [diagnostic(:invalid, path, "Expected the closed typed decision record")]
  end

  defp record_errors(record, module, family) do
    path = Atom.to_string(family)

    case closed_shape(record, module, path) do
      [] -> checks(record, family, path)
      errors -> errors
    end
  end

  defp checks(d, :contract_identity, p), do: string(d.contract_id, p <> ".contract_id")

  defp checks(d, :classification, p),
    do:
      enum(d.category, ComponentContract.categories(), p <> ".category") ++
        intent(d.module_intent, p <> ".module_intent") ++
        intent(d.function_intent, p <> ".function_intent")

  defp checks(d, :boundary, p) do
    cond do
      d.multi_root_unsupported == true and d.boundary_node_id == nil ->
        [
          diagnostic(
            :multi_root_unsupported,
            p,
            "Multi-root component boundaries are unsupported"
          )
        ]

      d.multi_root_unsupported in [nil, false] ->
        string(d.boundary_node_id, p <> ".boundary_node_id")

      true ->
        [diagnostic(:invalid, p, "Boundary must declare exactly one mode")]
    end
  end

  defp checks(d, family, p) when family in [:public_attrs, :item_fields] do
    owner =
      if family == :item_fields,
        do: string(d.source_collection_binding_id, p <> ".source_collection_binding_id"),
        else: []

    owner ++ member(d, p) ++ enum(d.type, Attr.phoenix_types(), p <> ".type") ++ default(d, p)
  end

  defp checks(d, :public_slots, p),
    do:
      member(d, p) ++
        enum(d.cardinality, [Slot.first_wave_cardinality()], p <> ".cardinality") ++
        string(d.consumer_responsibility, p <> ".consumer_responsibility")

  defp checks(d, :collection_admissions, p) do
    string(d.source_collection_binding_id, p <> ".source_collection_binding_id") ++
      json_object(d.provenance, p <> ".provenance") ++
      cond do
        d.parent_collection_binding_id == nil and d.parent_item_field_name == nil ->
          public_name(d.public_attr_name, p <> ".public_attr_name")

        d.public_attr_name == nil ->
          string(d.parent_collection_binding_id, p <> ".parent_collection_binding_id") ++
            public_name(d.parent_item_field_name, p <> ".parent_item_field_name")

        true ->
          [diagnostic(:invalid, p, "Collection location must be root XOR nested")]
      end
  end

  defp checks(d, :collection_count_links, p),
    do:
      string(d.source_collection_binding_id, p <> ".source_collection_binding_id") ++
        public_name(d.count_public_name, p <> ".count_public_name") ++
        string(d.count_value_binding_id, p <> ".count_value_binding_id")

  defp checks(d, :binding_assignments, p) do
    enum(d.source_binding_kind, [:collection, :value], p <> ".source_binding_kind") ++
      string(d.source_binding_id, p <> ".source_binding_id") ++
      enum(d.assignment_kind, @assignment_kinds, p <> ".assignment_kind") ++
      assignment_shape(d, p)
  end

  defp checks(d, :render_placements, p),
    do:
      enum(d.public_target_kind, [:attr, :slot], p <> ".public_target_kind") ++
        public_name(d.public_target_name, p <> ".public_target_name") ++
        string(d.target_node_id, p <> ".target_node_id") ++
        enum(d.render_role, ComponentizationPlan.render_roles(), p <> ".render_role")

  defp checks(d, :image_accessibility, p) do
    enum(d.target_kind, [:attr, :item_field], p <> ".target_kind") ++
      public_name(d.target_name, p <> ".target_name") ++
      if(d.target_kind == :item_field,
        do: string(d.source_collection_binding_id, p <> ".source_collection_binding_id"),
        else: absent(d.source_collection_binding_id, p <> ".source_collection_binding_id")
      ) ++
      json_object(d.accessibility, p <> ".accessibility") ++
      require_valid(image_policy?(d), p, "Image accessibility must use an exact closed D3 policy")
  end

  defp checks(d, :evidence_handling, p),
    do:
      enum(d.source_binding_kind, [:value], p <> ".source_binding_kind") ++
        string(d.source_binding_id, p <> ".source_binding_id") ++
        enum(d.outcome, [:omit_public_projection], p <> ".outcome")

  defp checks(d, :static_content_dispositions, p) do
    enum(d.target_kind, [:internal_node, :promote_attr, :promote_slot], p <> ".target_kind") ++
      if d.target_kind == :internal_node,
        do:
          string(d.design_node_id, p <> ".design_node_id") ++
            absent(d.public_target_name, p <> ".public_target_name"),
        else:
          public_name(d.public_target_name, p <> ".public_target_name") ++
            absent(d.design_node_id, p <> ".design_node_id")
  end

  defp member(d, p),
    do:
      public_name(d.name, p <> ".name") ++
        string(d.semantic_purpose, p <> ".semantic_purpose") ++
        require_valid(
          is_boolean(d.required),
          p <> ".required",
          "Required must be an explicit boolean"
        ) ++
        Enum.flat_map(
          [:validation, :accessibility, :provenance],
          &json_object(Map.fetch!(d, &1), p <> "." <> Atom.to_string(&1))
        )

  defp default(%{default: :not_supplied}, p),
    do: [
      diagnostic(
        :missing_decision,
        p <> ".default",
        "Default must be supplied explicitly, including nil"
      )
    ]

  defp default(d, p),
    do:
      require_valid(json_value?(d.default), p <> ".default", "Default must be JSON-compatible") ++
        require_valid(
          not (d.required == true and d.default != nil),
          p <> ".default",
          "Required members cannot have a default"
        )

  defp assignment_shape(d, p) do
    required =
      case d.assignment_kind do
        :scalar_attr ->
          [:public_attr_name]

        :collection_attr ->
          [:public_attr_name, :source_collection_binding_id]

        :collection_item_field_value ->
          [:item_field_name, :source_collection_binding_id]

        :collection_item_field_nested_collection ->
          [:parent_item_field_name, :source_collection_binding_id]

        :collection_count_attr ->
          [:public_attr_name, :source_collection_binding_id]

        :collection_count_item_field ->
          [:parent_item_field_name, :source_collection_binding_id]

        :slot ->
          [:public_slot_name]

        _ ->
          []
      end

    Enum.flat_map(@target_fields, fn field ->
      value = Map.fetch!(d, field)

      if field in required,
        do: string(value, p <> "." <> Atom.to_string(field)),
        else: absent(value, p <> "." <> Atom.to_string(field))
    end)
  end

  defp image_policy?(%{accessibility: %{"image_alt_policy" => "decorative"} = map}),
    do: map_size(map) == 1

  defp image_policy?(%{
         target_kind: kind,
         accessibility:
           %{"image_alt_policy" => "consumer_supplied", "required_when_source_present" => true} =
             map
       }) do
    alt_key = if kind == :attr, do: "alt_attr_name", else: "alt_item_field_name"
    map_size(map) == 3 and nonempty?(Map.get(map, alt_key))
  end

  defp image_policy?(_), do: false

  defp indexes(input, document) do
    assignments_by_target =
      Enum.reduce(input.binding_assignments, %{}, fn d, acc ->
        Map.update(acc, assignment_target(d, document.collection_bindings), [d], &[d | &1])
      end)

    %{
      nodes: index_nodes(document.root_nodes, %{}),
      values: document.value_bindings,
      collections: document.collection_bindings,
      attrs: Map.new(input.public_attrs, &{&1.name, &1}),
      slots: Map.new(input.public_slots, &{&1.name, &1}),
      fields: Map.new(input.item_fields, &{{&1.source_collection_binding_id, &1.name}, &1}),
      admissions: Map.new(input.collection_admissions, &{&1.source_collection_binding_id, &1}),
      counts: Map.new(input.collection_count_links, &{&1.source_collection_binding_id, &1}),
      assignments:
        Map.new(input.binding_assignments, &{{&1.source_binding_kind, &1.source_binding_id}, &1}),
      assignments_by_target: assignments_by_target,
      renders:
        Map.new(input.render_placements, &{{&1.public_target_kind, &1.public_target_name}, &1}),
      images: Map.new(input.image_accessibility, &{image_target(&1), &1}),
      evidence:
        Map.new(input.evidence_handling, &{{&1.source_binding_kind, &1.source_binding_id}, &1})
    }
  end

  # Each node contributes one lookup entry. No per-decision subtree scans.
  defp index_nodes([], index), do: index

  defp index_nodes([node | rest], index) do
    index = Map.put(index, node.node_id, node)
    index = index_nodes(node.children, index)
    index_nodes(rest, index)
  end

  defp relationship_errors(input, i) do
    boundary = exists(i.nodes, input.boundary.boundary_node_id, "boundary", "Boundary node")

    identity =
      require_valid(
        not Map.has_key?(i.nodes, input.contract_identity.contract_id),
        "contract_identity",
        "Contract identity must not be a DesignNode identity"
      )

    collisions =
      Enum.flat_map(input.public_attrs, fn d ->
        if Map.has_key?(i.slots, d.name),
          do: [
            diagnostic(:conflict, "public_attrs." <> d.name, "Attr and slot public names collide")
          ],
          else: []
      end)

    boundary ++
      identity ++
      collisions ++
      Enum.flat_map(input.collection_admissions, &admission_errors(&1, i)) ++
      Enum.flat_map(
        input.item_fields,
        &exists(i.admissions, &1.source_collection_binding_id, "item_fields", "Admitted owner")
      ) ++
      Enum.flat_map(input.collection_count_links, &count_errors(&1, i)) ++
      Enum.flat_map(input.binding_assignments, &assignment_errors(&1, i)) ++
      Enum.flat_map(input.render_placements, &render_errors(&1, i)) ++
      Enum.flat_map(input.evidence_handling, &evidence_errors(&1, i)) ++
      Enum.flat_map(input.static_content_dispositions, &static_errors(&1, i)) ++
      image_errors(input, i)
  end

  defp admission_errors(d, i) do
    p = "collection_admissions." <> d.source_collection_binding_id

    case Map.get(i.collections, d.source_collection_binding_id) do
      nil ->
        [diagnostic(:invalid, p, "Collection binding does not resolve")]

      binding ->
        if binding.parent_collection_binding_id == nil do
          require_valid(
            d.parent_collection_binding_id == nil and d.parent_item_field_name == nil and
              member_type?(i.attrs, d.public_attr_name, :list),
            p,
            "Root admission must name an explicit list attr"
          )
        else
          require_valid(
            d.public_attr_name == nil and
              d.parent_collection_binding_id == binding.parent_collection_binding_id and
              Map.has_key?(i.admissions, binding.parent_collection_binding_id) and
              member_type?(
                i.fields,
                {binding.parent_collection_binding_id, d.parent_item_field_name},
                :list
              ),
            p,
            "Nested admission must agree with IR parent and explicit parent list field"
          )
        end
    end
  end

  defp count_errors(d, i) do
    p = "collection_count_links." <> d.source_collection_binding_id
    admission = Map.get(i.admissions, d.source_collection_binding_id)
    value = Map.get(i.values, d.count_value_binding_id)
    assignment = Map.get(i.assignments, {:value, d.count_value_binding_id})

    require_valid(
      admission != nil and count_value?(value, d.source_collection_binding_id) and
        count_target?(d, admission, i) and count_assignment?(d, admission, assignment),
      p,
      "Count link must agree with admitted collection, integer target and explicit count assignment"
    )
  end

  defp count_value?(
         %{value_kind: :collection_count, scope: :collection, collection_binding_id: owner},
         id
       ),
       do: owner == id

  defp count_value?(_, _), do: false
  defp count_target?(_, nil, _), do: false

  defp count_target?(d, %{parent_collection_binding_id: nil}, i),
    do: count_member?(Map.get(i.attrs, d.count_public_name))

  defp count_target?(d, admission, i),
    do:
      count_member?(
        Map.get(i.fields, {admission.parent_collection_binding_id, d.count_public_name})
      )

  defp count_member?(%{type: :integer, validation: validation}),
    do: LiveFrames.ComponentContract.Validation.non_negative_validation?(validation)

  defp count_member?(_), do: false
  defp count_assignment?(_, nil, _), do: false

  defp count_assignment?(
         d,
         %{parent_collection_binding_id: nil},
         %{assignment_kind: :collection_count_attr} = a
       ),
       do:
         a.source_collection_binding_id == d.source_collection_binding_id and
           a.public_attr_name == d.count_public_name

  defp count_assignment?(d, admission, %{assignment_kind: :collection_count_item_field} = a),
    do:
      admission.parent_collection_binding_id != nil and
        a.source_collection_binding_id == d.source_collection_binding_id and
        a.parent_item_field_name == d.count_public_name

  defp count_assignment?(_, _, _), do: false

  defp assignment_errors(d, i) do
    p =
      "binding_assignments." <>
        Atom.to_string(d.source_binding_kind) <> "." <> d.source_binding_id

    source =
      if d.source_binding_kind == :value,
        do: Map.get(i.values, d.source_binding_id),
        else: Map.get(i.collections, d.source_binding_id)

    cond do
      source == nil ->
        [diagnostic(:invalid, p, "Source binding kind and identity do not resolve")]

      Map.get(source, :normalization_status) == :evidence_insufficient ->
        [diagnostic(:conflict, p, "Evidence-insufficient bindings cannot be assigned")]

      true ->
        require_valid(
          assignment_valid?(d, source, i),
          p,
          "Assignment discriminant, IR scope, ownership and public target must agree"
        )
    end
  end

  defp assignment_valid?(
         %{assignment_kind: :scalar_attr, source_binding_kind: :value} = d,
         %{value_kind: :field, scope: :site, collection_binding_id: nil},
         i
       ),
       do: Map.has_key?(i.attrs, d.public_attr_name)

  defp assignment_valid?(
         %{assignment_kind: :slot, source_binding_kind: :value} = d,
         %{value_kind: :field, scope: :site, collection_binding_id: nil},
         i
       ),
       do: Map.has_key?(i.slots, d.public_slot_name)

  defp assignment_valid?(
         %{assignment_kind: :collection_attr, source_binding_kind: :collection} = d,
         %{parent_collection_binding_id: nil},
         i
       ) do
    case Map.get(i.admissions, d.source_binding_id) do
      %{public_attr_name: name, parent_collection_binding_id: nil} ->
        d.source_collection_binding_id == d.source_binding_id and name == d.public_attr_name and
          member_type?(i.attrs, name, :list)

      _ ->
        false
    end
  end

  defp assignment_valid?(
         %{assignment_kind: :collection_item_field_value, source_binding_kind: :value} = d,
         %{value_kind: :field, scope: :collection_item, collection_binding_id: owner},
         i
       ),
       do:
         owner == d.source_collection_binding_id and Map.has_key?(i.admissions, owner) and
           Map.has_key?(i.fields, {owner, d.item_field_name})

  defp assignment_valid?(
         %{
           assignment_kind: :collection_item_field_nested_collection,
           source_binding_kind: :collection
         } = d,
         %{parent_collection_binding_id: parent},
         i
       )
       when not is_nil(parent) do
    case Map.get(i.admissions, d.source_binding_id) do
      %{parent_collection_binding_id: ^parent, parent_item_field_name: name} ->
        d.source_collection_binding_id == d.source_binding_id and name == d.parent_item_field_name and
          member_type?(i.fields, {parent, name}, :list)

      _ ->
        false
    end
  end

  defp assignment_valid?(%{assignment_kind: kind, source_binding_kind: :value} = d, value, i)
       when kind in [:collection_count_attr, :collection_count_item_field] do
    case Map.get(i.counts, d.source_collection_binding_id) do
      nil ->
        false

      link ->
        link.count_value_binding_id == d.source_binding_id and
          count_value?(value, d.source_collection_binding_id) and
          count_target?(link, Map.get(i.admissions, d.source_collection_binding_id), i) and
          count_assignment?(link, Map.get(i.admissions, d.source_collection_binding_id), d)
    end
  end

  defp assignment_valid?(_, _, _), do: false

  defp render_errors(d, i) do
    target = {d.public_target_kind, d.public_target_name}
    members = if d.public_target_kind == :attr, do: i.attrs, else: i.slots

    exists(members, d.public_target_name, "render_placements", "Public member") ++
      exists(i.nodes, d.target_node_id, "render_placements", "Target node") ++
      if Map.has_key?(i.assignments_by_target, target),
        do: [
          diagnostic(
            :conflict,
            "render_placements",
            "Public target has both binding and render ownership"
          )
        ],
        else: []
  end

  defp evidence_errors(d, i) do
    value = Map.get(i.values, d.source_binding_id)

    require_valid(
      match?(%{normalization_status: :evidence_insufficient}, value),
      "evidence_handling",
      "Evidence handling requires an evidence-insufficient ValueBinding"
    ) ++
      if Map.has_key?(i.assignments, {:value, d.source_binding_id}),
        do: [diagnostic(:conflict, "evidence_handling", "Omission and assignment cannot coexist")],
        else: []
  end

  defp static_errors(%{target_kind: :internal_node} = d, i),
    do: exists(i.nodes, d.design_node_id, "static_content_dispositions", "Internal node")

  defp static_errors(%{target_kind: :promote_attr} = d, i),
    do: exists(i.attrs, d.public_target_name, "static_content_dispositions", "Promoted attr")

  defp static_errors(d, i),
    do: exists(i.slots, d.public_target_name, "static_content_dispositions", "Promoted slot")

  defp image_errors(input, i) do
    sources =
      Enum.reduce(input.render_placements, %{}, fn
        %{public_target_kind: :attr, render_role: :asset_src} = d, acc ->
          Map.put(acc, {:attr, d.public_target_name}, Map.get(i.attrs, d.public_target_name))

        _, acc ->
          acc
      end)

    sources =
      Enum.reduce(input.binding_assignments, sources, fn d, acc ->
        case {d.source_binding_kind, Map.get(i.values, d.source_binding_id)} do
          {:value, %{target_kind: :asset, target_node_id: node_id} = value} ->
            if match?(%{semantic_type: "image"}, Map.get(i.nodes, node_id)) do
              case {d.assignment_kind, value} do
                {:scalar_attr, _} ->
                  Map.put(acc, {:attr, d.public_attr_name}, Map.get(i.attrs, d.public_attr_name))

                {:collection_item_field_value, %{value_kind: :field, scope: :collection_item}} ->
                  Map.put(
                    acc,
                    {:item_field, d.source_collection_binding_id, d.item_field_name},
                    Map.get(i.fields, {d.source_collection_binding_id, d.item_field_name})
                  )

                _ ->
                  acc
              end
            else
              acc
            end

          _ ->
            acc
        end
      end)

    missing =
      Enum.flat_map(sources, fn {target, member} ->
        case Map.get(i.images, target) do
          nil ->
            [
              diagnostic(
                :missing_decision,
                "image_accessibility",
                "Image source #{inspect(target)} needs an accessibility decision"
              )
            ]

          decision ->
            require_valid(
              member != nil and member.accessibility == decision.accessibility,
              "image_accessibility",
              "Image source and accessibility decision must deep-equal",
              :conflict
            )
        end
      end)

    extra =
      Enum.flat_map(input.image_accessibility, fn d ->
        require_valid(
          Map.has_key?(sources, image_target(d)),
          "image_accessibility",
          "Accessibility decision has no structurally proven image source"
        )
      end)

    missing ++ extra
  end

  defp assignment_target(%{assignment_kind: :slot} = d, _), do: {:slot, d.public_slot_name}

  defp assignment_target(%{assignment_kind: kind} = d, _)
       when kind in [:scalar_attr, :collection_attr, :collection_count_attr],
       do: {:attr, d.public_attr_name}

  defp assignment_target(%{assignment_kind: :collection_item_field_value} = d, _),
    do: {:item_field, d.source_collection_binding_id, d.item_field_name}

  defp assignment_target(d, collections) do
    case Map.get(collections, d.source_collection_binding_id) do
      nil -> {:item_field, nil, d.parent_item_field_name}
      source -> {:item_field, source.parent_collection_binding_id, d.parent_item_field_name}
    end
  end

  defp image_target(%{target_kind: :attr} = d), do: {:attr, d.target_name}
  defp image_target(d), do: {:item_field, d.source_collection_binding_id, d.target_name}
  defp member_type?(map, key, type), do: match?(%{type: ^type}, Map.get(map, key))

  defp exists(index, key, p, label),
    do: require_valid(Map.has_key?(index, key), p, label <> " does not resolve")

  defp string(nil, p),
    do: [diagnostic(:missing_decision, p, "Explicit non-empty string is required")]

  defp string(value, p),
    do: require_valid(nonempty?(value), p, "Expected a non-empty UTF-8 string")

  defp nonempty?(value), do: is_binary(value) and value != "" and String.valid?(value)

  defp enum(nil, _, p),
    do: [diagnostic(:missing_decision, p, "Explicit enum decision is required")]

  defp enum(value, allowed, p),
    do: require_valid(value in allowed, p, "Unsupported decision enum")

  defp absent(value, p),
    do: require_valid(value == nil, p, "Field must be absent for this decision kind")

  defp intent(value, p),
    do:
      string(value, p) ++
        require_valid(not source_specific?(value), p, "Intent uses source-specific vocabulary")

  defp public_name(value, p),
    do:
      string(value, p) ++
        require_valid(
          is_binary(value) and Regex.match?(~r/^[a-z][a-z0-9_]*$/, value) and
            not source_specific?(value),
          p,
          "Expected a source-independent public identifier"
        )

  defp source_specific?(value) when is_binary(value),
    do:
      value in ~w(post_title featured_image query_results) or
        String.starts_with?(value, ["bricks_", "wp_", "element_"])

  defp source_specific?(_), do: false

  defp json_object(value, p),
    do: require_valid(json_object?(value), p, "Expected a JSON-safe object")

  defp json_object?(value) when is_map(value) and not is_struct(value) do
    case json_keys(Map.keys(value)) do
      {:ok, keys} ->
        length(keys) == length(Enum.uniq(keys)) and Enum.all?(Map.values(value), &json_value?/1)

      :error ->
        false
    end
  end

  defp json_object?(_), do: false

  defp json_keys(keys) do
    Enum.reduce_while(keys, [], fn key, acc ->
      case Json.key_string(key) do
        {:ok, key} -> {:cont, [key | acc]}
        :error -> {:halt, :error}
      end
    end)
    |> case do
      :error -> :error
      keys -> {:ok, keys}
    end
  end

  defp json_value?(nil), do: true
  defp json_value?(value) when is_binary(value) or is_boolean(value), do: true
  defp json_value?(value) when is_integer(value) or is_float(value), do: true
  defp json_value?(value) when is_list(value), do: Enum.all?(value, &json_value?/1)

  defp json_value?(value) when is_map(value) and not is_struct(value),
    do: json_object?(value)

  defp json_value?(_), do: false
  defp require_valid(true, _, _, _code), do: []
  defp require_valid(false, p, message, code), do: [diagnostic(code, p, message)]
  defp require_valid(condition, p, message), do: require_valid(condition, p, message, :invalid)

  defp diagnostic(code, path, message),
    do: %Diagnostic{
      code: "componentization_proposer.input." <> Atom.to_string(code),
      path: path,
      message: message
    }

  defp finish(errors),
    do: {:error, errors |> Enum.uniq() |> Enum.sort_by(&{&1.code, &1.path, &1.message})}
end
