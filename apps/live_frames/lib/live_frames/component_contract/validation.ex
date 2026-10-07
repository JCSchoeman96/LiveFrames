defmodule LiveFrames.ComponentContract.Validation do
  @moduledoc false

  alias LiveFrames.ComponentContract
  alias LiveFrames.ComponentContract.Attr
  alias LiveFrames.ComponentContract.BindingProjection
  alias LiveFrames.ComponentContract.CollectionInput
  alias LiveFrames.ComponentContract.Diagnostic
  alias LiveFrames.ComponentContract.ItemField
  alias LiveFrames.ComponentContract.Json
  alias LiveFrames.ComponentContract.ReferenceValidation
  alias LiveFrames.ComponentContract.Slot

  @banned_exact ~w(post_title featured_image query_results)
  @heading_values [1, 2, 3, 4, 5, 6]
  @name_pattern ~r/^[a-z][a-z0-9_]*$/
  @generation_token_pattern ~r/^[a-z][a-z0-9_]*$/
  @categories [:primitive, :component, :pattern, :section]
  @approval_statuses [:proposed, :approved, :needs_review, :rejected]
  @diagnostic_severities [:info, :warning, :error, :fatal]

  @spec validate(term()) :: :ok | {:error, [Diagnostic.t()]}
  def validate(%ComponentContract{} = contract) do
    diagnostics = []
    diagnostics = validate_root(contract, diagnostics)

    {attrs_by_name, diagnostics} =
      validate_attrs(contract.public_attrs, "public_attrs", diagnostics)

    {slots_by_name, diagnostics} =
      validate_slots(contract.public_slots, "public_slots", diagnostics)

    diagnostics = validate_public_name_conflicts(attrs_by_name, slots_by_name, diagnostics)

    diagnostics =
      diagnostics
      |> validate_intent_name(contract.module_intent, "module_intent")
      |> validate_intent_name(contract.function_intent, "function_intent")

    {collection_by_id, item_fields_index, diagnostics} =
      validate_collection_inputs(contract.collection_inputs, attrs_by_name, diagnostics)

    diagnostics =
      validate_binding_projections(
        contract.binding_projections,
        attrs_by_name,
        slots_by_name,
        collection_by_id,
        item_fields_index,
        diagnostics
      )

    diagnostics = validate_stored_diagnostics(diagnostics, contract.diagnostics)
    finish(diagnostics)
  end

  def validate(_contract) do
    finish([err("component_contract.contract.invalid", "expected a ComponentContract struct")])
  end

  @spec validate_for_generation(ComponentContract.t(), LiveFrames.IR.DesignDocument.t()) ::
          :ok | {:error, [Diagnostic.t()]}
  def validate_for_generation(%ComponentContract{} = contract, design_document) do
    if contract.approval_status != :approved do
      finish([
        err("component_contract.approval_blocked", "contract is not approved for generation")
      ])
    else
      validate_generation_prerequisites(contract, design_document)
    end
  end

  def validate_for_generation(_contract, _document) do
    finish([err("component_contract.contract.invalid", "expected a ComponentContract struct")])
  end

  @spec validate_generation_prerequisites(term(), term()) :: :ok | {:error, [Diagnostic.t()]}
  def validate_generation_prerequisites(%ComponentContract{} = contract, design_document) do
    case validate(contract) do
      {:error, diagnostics} ->
        finish(diagnostics)

      :ok ->
        diagnostics =
          case ReferenceValidation.validate(contract, design_document) do
            :ok -> []
            {:error, values} -> values
          end

        diagnostics =
          Enum.reduce(contract.diagnostics, diagnostics, fn
            %Diagnostic{severity: severity} = diagnostic, acc
            when severity in [:error, :fatal] ->
              [diagnostic | acc]

            _, acc ->
              acc
          end)

        diagnostics =
          diagnostics ++
            generation_capability_diagnostics(contract) ++ generation_intent_diagnostics(contract)

        finish(diagnostics)
    end
  rescue
    _error ->
      finish([
        err("component_contract.contract.invalid", "generation prerequisite inputs are malformed")
      ])
  catch
    _kind, _reason ->
      finish([
        err("component_contract.contract.invalid", "generation prerequisite inputs are malformed")
      ])
  end

  def validate_generation_prerequisites(_contract, _document) do
    finish([err("component_contract.contract.invalid", "expected a ComponentContract struct")])
  end

  defp generation_capability_diagnostics(contract) do
    attrs_any =
      Enum.any?(contract.public_attrs, fn %Attr{type: t} -> t == :any end)

    fields_any =
      Enum.any?(contract.collection_inputs, fn %CollectionInput{item_fields: fields} ->
        Enum.any?(fields, fn %ItemField{type: t} -> t == :any end)
      end)

    bad_slots =
      Enum.any?(contract.public_slots, fn %Slot{cardinality: c} ->
        c != Slot.first_wave_cardinality()
      end)

    type_diagnostics =
      cond do
        attrs_any or fields_any ->
          [
            err(
              "component_contract.attr.type_invalid",
              ":any is not generation-eligible in format 1.0.0"
            )
          ]

        bad_slots ->
          [
            err(
              "component_contract.slot.cardinality_invalid",
              "only first-wave slot cardinality is generation-eligible"
            )
          ]

        true ->
          []
      end

    type_diagnostics ++
      generation_item_field_type_diagnostics(contract) ++
      generation_validation_diagnostics(contract) ++
      generation_default_diagnostics(contract)
  end

  defp generation_item_field_type_diagnostics(contract) do
    contract.collection_inputs
    |> Enum.with_index()
    |> Enum.flat_map(fn {%CollectionInput{item_fields: fields}, collection_index} ->
      fields
      |> Enum.with_index()
      |> Enum.flat_map(fn
        {%ItemField{type: :global}, field_index} ->
          [
            err_at(
              "component_contract.item_field.type_invalid",
              ":global is not generation-eligible for collection item fields",
              path: "collection_inputs[#{collection_index}].item_fields[#{field_index}].type"
            )
          ]

        _ ->
          []
      end)
    end)
  end

  defp generation_validation_diagnostics(contract) do
    count_attr_names = generation_count_attr_names(contract)
    count_item_fields = generation_count_item_fields(contract)

    attr_diagnostics =
      contract.public_attrs
      |> Enum.with_index()
      |> Enum.flat_map(fn {%Attr{name: name, type: type, validation: validation}, index} ->
        generation_validation_diagnostic(
          validation,
          type,
          MapSet.member?(count_attr_names, name),
          "public_attrs[#{index}].validation"
        )
      end)

    item_field_diagnostics =
      contract.collection_inputs
      |> Enum.with_index()
      |> Enum.flat_map(fn {%CollectionInput{
                             source_collection_binding_id: collection_id,
                             item_fields: fields
                           }, collection_index} ->
        fields
        |> Enum.with_index()
        |> Enum.flat_map(fn {%ItemField{name: name, type: type, validation: validation},
                             field_index} ->
          generation_validation_diagnostic(
            validation,
            type,
            MapSet.member?(count_item_fields, {collection_id, name}),
            "collection_inputs[#{collection_index}].item_fields[#{field_index}].validation"
          )
        end)
      end)

    attr_diagnostics ++ item_field_diagnostics
  end

  defp generation_validation_diagnostic(validation, type, count?, path) do
    case Json.normalize(validation) do
      {:ok, normalized} ->
        if supported_generation_validation?(normalized, type, count?) do
          []
        else
          [
            err_at(
              "component_contract.generation.validation_unsupported",
              "validation metadata is not supported for native generation",
              path: path
            )
          ]
        end

      :error ->
        [
          err_at(
            "component_contract.generation.validation_unsupported",
            "validation metadata is not supported for native generation",
            path: path
          )
        ]
    end
  end

  defp supported_generation_validation?(%{} = validation, type, count?) do
    cond do
      map_size(validation) == 0 ->
        true

      count? ->
        count_validation_supported?(validation)

      type == :integer ->
        validation == %{"values" => @heading_values}

      true ->
        false
    end
  end

  defp count_validation_supported?(%{"min" => min} = validation)
       when map_size(validation) == 1 and is_number(min),
       do: min >= 0

  defp count_validation_supported?(_validation), do: false

  defp generation_count_attr_names(contract) do
    contract.collection_inputs
    |> Enum.map(& &1.count_attr_name)
    |> Enum.reject(&is_nil/1)
    |> MapSet.new()
  end

  defp generation_count_item_fields(contract) do
    contract.collection_inputs
    |> Enum.flat_map(fn
      %CollectionInput{
        parent_collection_binding_id: parent_id,
        count_item_field_name: field_name
      }
      when is_binary(parent_id) and is_binary(field_name) ->
        [{parent_id, field_name}]

      _ ->
        []
    end)
    |> MapSet.new()
  end

  defp generation_default_diagnostics(contract) do
    attr_diagnostics =
      contract.public_attrs
      |> Enum.with_index()
      |> Enum.flat_map(fn {%Attr{default: default}, index} ->
        generation_default_diagnostic(default, "public_attrs[#{index}].default")
      end)

    item_field_diagnostics =
      contract.collection_inputs
      |> Enum.with_index()
      |> Enum.flat_map(fn {%CollectionInput{item_fields: fields}, collection_index} ->
        fields
        |> Enum.with_index()
        |> Enum.flat_map(fn {%ItemField{default: default}, field_index} ->
          generation_default_diagnostic(
            default,
            "collection_inputs[#{collection_index}].item_fields[#{field_index}].default"
          )
        end)
      end)

    attr_diagnostics ++ item_field_diagnostics
  end

  defp generation_default_diagnostic(nil, _path), do: []

  defp generation_default_diagnostic(default, path) do
    case Json.normalize(default) do
      {:ok, normalized} ->
        case LiveFrames.NativeGenerator.Literal.render(normalized) do
          {:ok, _} ->
            []

          {:error, _} ->
            [
              err_at(
                "component_contract.generation.default_unrepresentable",
                "default cannot be represented as a canonical JSON literal",
                path: path
              )
            ]
        end

      :error ->
        [
          err_at(
            "component_contract.generation.default_unrepresentable",
            "default cannot be represented as a canonical JSON literal",
            path: path
          )
        ]
    end
  end

  defp generation_intent_diagnostics(contract) do
    [
      {:module_intent, contract.module_intent},
      {:function_intent, contract.function_intent}
    ]
    |> Enum.flat_map(fn {field, value} ->
      if valid_string?(value) and Regex.match?(@generation_token_pattern, value) do
        []
      else
        [
          err_at(
            "component_contract.generation.intent_invalid",
            "intent must match the generation token grammar",
            path: Atom.to_string(field)
          )
        ]
      end
    end)
  end

  defp validate_root(contract, diagnostics) do
    diagnostics
    |> validate_format_version(contract.contract_format_version)
    |> validate_contract_id(contract.contract_id)
    |> validate_category(contract.category)
    |> validate_approval_status(contract.approval_status)
    |> require_list(
      contract.public_attrs,
      "component_contract.contract.invalid",
      "public_attrs must be a list"
    )
    |> require_list(
      contract.public_slots,
      "component_contract.contract.invalid",
      "public_slots must be a list"
    )
    |> require_list(
      contract.collection_inputs,
      "component_contract.contract.invalid",
      "collection_inputs must be a list"
    )
    |> require_list(
      contract.binding_projections,
      "component_contract.contract.invalid",
      "binding_projections must be a list"
    )
    |> require_list(
      contract.diagnostics,
      "component_contract.contract.invalid",
      "diagnostics must be a list"
    )
    |> require_json_object(
      contract.provenance,
      "component_contract.metadata.invalid",
      "provenance must be a JSON object"
    )
  end

  defp validate_format_version(diagnostics, version) do
    cond do
      version == ComponentContract.current_format_version() ->
        diagnostics

      valid_string?(version) ->
        add(
          diagnostics,
          err(
            "component_contract.version.unsupported",
            "contract_format_version is not supported"
          )
        )

      true ->
        add(
          diagnostics,
          err("component_contract.version.invalid", "contract_format_version must be a string")
        )
    end
  end

  defp validate_contract_id(diagnostics, id) do
    if non_empty_string?(id) do
      diagnostics
    else
      add(
        diagnostics,
        err("component_contract.identity.invalid", "contract_id must be a non-empty string")
      )
    end
  end

  defp validate_category(diagnostics, category) when category in @categories, do: diagnostics

  defp validate_category(diagnostics, _) do
    add(diagnostics, err("component_contract.category.invalid", "category is not supported"))
  end

  defp validate_approval_status(diagnostics, status) when status in @approval_statuses,
    do: diagnostics

  defp validate_approval_status(diagnostics, _) do
    add(
      diagnostics,
      err("component_contract.approval_status.invalid", "approval_status is not supported")
    )
  end

  defp validate_attrs(attrs, base_path, diagnostics) when is_list(attrs) do
    if proper_list?(attrs) do
      {by_name, diagnostics} =
        Enum.reduce(attrs, {%{}, diagnostics}, fn attr, {by_name, diagnostics} ->
          path = "#{base_path}[#{map_size(by_name)}]"

          case attr do
            %Attr{} = a ->
              diagnostics = validate_attr(a, path, diagnostics)

              case Map.fetch(by_name, a.name) do
                {:ok, _} ->
                  {by_name,
                   add(
                     diagnostics,
                     err_at(
                       "component_contract.attr.name_duplicate",
                       "public attr names must be unique",
                       path: "#{path}.name"
                     )
                   )}

                :error ->
                  {Map.put(by_name, a.name, a), diagnostics}
              end

            _ ->
              {by_name,
               add(
                 diagnostics,
                 err_at("component_contract.attr.invalid", "expected Attr struct", path: path)
               )}
          end
        end)

      {by_name, diagnostics}
    else
      validate_attrs(nil, base_path, diagnostics)
    end
  end

  defp validate_attrs(_attrs, _base_path, diagnostics) do
    {%{}, add(diagnostics, err("component_contract.attr.invalid", "public_attrs must be a list"))}
  end

  defp validate_attr(%Attr{} = attr, path, diagnostics) do
    diagnostics
    |> validate_public_name(attr.name, path <> ".name")
    |> validate_phoenix_type(attr.type, path <> ".type")
    |> validate_required_default(attr.required, attr.default, path)
    |> validate_semantic_purpose(attr.semantic_purpose, path)
    |> require_json_object(
      attr.validation,
      "component_contract.metadata.invalid",
      "validation must be a JSON object",
      path <> ".validation"
    )
    |> require_json_object(
      attr.accessibility,
      "component_contract.metadata.invalid",
      "accessibility must be a JSON object",
      path <> ".accessibility"
    )
    |> require_json_object(
      attr.provenance,
      "component_contract.metadata.invalid",
      "provenance must be a JSON object",
      path <> ".provenance"
    )
    |> validate_json_default(attr.default, path <> ".default")
  end

  defp validate_slots(slots, base_path, diagnostics) when is_list(slots) do
    if proper_list?(slots) do
      {by_name, diagnostics} =
        Enum.reduce(slots, {%{}, diagnostics}, fn slot, {by_name, diagnostics} ->
          path = "#{base_path}[#{map_size(by_name)}]"

          case slot do
            %Slot{} = s ->
              diagnostics = validate_slot(s, path, diagnostics)

              case Map.fetch(by_name, s.name) do
                {:ok, _} ->
                  {by_name,
                   add(
                     diagnostics,
                     err_at(
                       "component_contract.slot.name_duplicate",
                       "public slot names must be unique",
                       path: "#{path}.name"
                     )
                   )}

                :error ->
                  {Map.put(by_name, s.name, s), diagnostics}
              end

            _ ->
              {by_name,
               add(
                 diagnostics,
                 err_at("component_contract.slot.invalid", "expected Slot struct", path: path)
               )}
          end
        end)

      {by_name, diagnostics}
    else
      validate_slots(nil, base_path, diagnostics)
    end
  end

  defp validate_slots(_slots, _base_path, diagnostics) do
    {%{}, add(diagnostics, err("component_contract.slot.invalid", "public_slots must be a list"))}
  end

  defp validate_slot(%Slot{} = slot, path, diagnostics) do
    diagnostics
    |> validate_public_name(slot.name, path <> ".name")
    |> validate_boolean_required_flag(slot.required, path <> ".required")
    |> then(fn d ->
      if non_empty_string?(slot.cardinality) do
        if slot.cardinality == Slot.first_wave_cardinality() do
          d
        else
          add(
            d,
            err_at("component_contract.slot.cardinality_invalid", "unsupported slot cardinality",
              path: path <> ".cardinality"
            )
          )
        end
      else
        add(
          d,
          err_at("component_contract.slot.invalid", "cardinality must be a non-empty string",
            path: path <> ".cardinality"
          )
        )
      end
    end)
    |> validate_semantic_purpose(slot.semantic_purpose, path)
    |> then(fn d ->
      if non_empty_string?(slot.consumer_responsibility) do
        d
      else
        add(
          d,
          err_at(
            "component_contract.slot.consumer_responsibility_missing",
            "consumer_responsibility is required",
            path: path
          )
        )
      end
    end)
    |> require_json_object(
      slot.validation,
      "component_contract.metadata.invalid",
      "validation must be a JSON object",
      path <> ".validation"
    )
    |> require_json_object(
      slot.accessibility,
      "component_contract.metadata.invalid",
      "accessibility must be a JSON object",
      path <> ".accessibility"
    )
    |> require_json_object(
      slot.provenance,
      "component_contract.metadata.invalid",
      "provenance must be a JSON object",
      path <> ".provenance"
    )
  end

  defp validate_collection_inputs(inputs, attrs_by_name, diagnostics) when is_list(inputs) do
    if proper_list?(inputs) do
      {by_id, item_index, diagnostics} =
        Enum.reduce(inputs, {%{}, %{}, diagnostics}, fn input, {by_id, item_index, diagnostics} ->
          case input do
            %CollectionInput{} = ci ->
              idx = map_size(by_id)
              path = "collection_inputs[#{idx}]"
              diagnostics = validate_collection_input_shape(ci, path, diagnostics)

              id = ci.source_collection_binding_id

              diagnostics =
                if is_binary(id) and id != "" and Map.has_key?(by_id, id) do
                  add(
                    diagnostics,
                    err_at(
                      "component_contract.collection.id_duplicate",
                      "source_collection_binding_id must be unique",
                      path: path <> ".source_collection_binding_id"
                    )
                  )
                else
                  diagnostics
                end

              {item_fields_by_name, diagnostics} =
                validate_item_fields(ci.item_fields, path <> ".item_fields", diagnostics)

              item_index =
                Map.put(item_index, id, item_fields_by_name)

              if non_empty_string?(id) do
                {Map.put(by_id, id, ci), item_index, diagnostics}
              else
                {by_id, item_index, diagnostics}
              end

            _ ->
              {by_id, item_index,
               add(
                 diagnostics,
                 err("component_contract.collection.invalid", "expected CollectionInput struct")
               )}
          end
        end)

      diagnostics = validate_collection_locations(by_id, attrs_by_name, item_index, diagnostics)
      cyclic_ids = collection_cycle_ids(by_id)

      diagnostics =
        validate_collection_graph(by_id, attrs_by_name, item_index, cyclic_ids, diagnostics)

      {by_id, item_index, diagnostics}
    else
      validate_collection_inputs(nil, attrs_by_name, diagnostics)
    end
  end

  defp validate_collection_inputs(_inputs, _attrs, diagnostics) do
    {%{}, %{},
     add(
       diagnostics,
       err("component_contract.collection.invalid", "collection_inputs must be a list")
     )}
  end

  defp validate_collection_input_shape(%CollectionInput{} = ci, path, diagnostics) do
    diagnostics
    |> then(fn d ->
      if non_empty_string?(ci.source_collection_binding_id) do
        d
      else
        add(
          d,
          err_at(
            "component_contract.collection.invalid",
            "source_collection_binding_id is required",
            path: path
          )
        )
      end
    end)
    |> then(fn d ->
      Enum.reduce(
        [
          :public_attr_name,
          :parent_collection_binding_id,
          :parent_item_field_name,
          :count_attr_name,
          :count_item_field_name
        ],
        d,
        fn field, acc ->
          validate_optional_artifact_string(
            acc,
            Map.fetch!(ci, field),
            "component_contract.collection.invalid",
            path <> "." <> Atom.to_string(field)
          )
        end
      )
    end)
    |> require_json_object(
      ci.provenance,
      "component_contract.metadata.invalid",
      "provenance must be a JSON object",
      path <> ".provenance"
    )
    |> validate_count_location_fields(ci, path)
  end

  defp validate_count_location_fields(diagnostics, %CollectionInput{} = ci, path) do
    top? =
      ci.public_attr_name != nil and ci.parent_collection_binding_id == nil and
        ci.parent_item_field_name == nil

    nested? =
      ci.public_attr_name == nil and ci.parent_collection_binding_id != nil and
        ci.parent_item_field_name != nil

    diagnostics =
      cond do
        top? or nested? ->
          diagnostics

        ci.public_attr_name != nil and
            (ci.parent_collection_binding_id != nil or ci.parent_item_field_name != nil) ->
          add(
            diagnostics,
            err_at(
              "component_contract.collection.location_invalid",
              "collection location fields conflict",
              path: path
            )
          )

        ci.parent_collection_binding_id != nil and ci.parent_item_field_name == nil ->
          add(
            diagnostics,
            err_at(
              "component_contract.collection.location_invalid",
              "nested location requires parent_item_field_name",
              path: path
            )
          )

        ci.parent_collection_binding_id == nil and ci.parent_item_field_name != nil ->
          add(
            diagnostics,
            err_at(
              "component_contract.collection.location_invalid",
              "nested location requires parent_collection_binding_id",
              path: path
            )
          )

        true ->
          add(
            diagnostics,
            err_at(
              "component_contract.collection.location_invalid",
              "collection location is not established",
              path: path
            )
          )
      end

    both_count = ci.count_attr_name != nil and ci.count_item_field_name != nil

    diagnostics =
      if both_count do
        add(
          diagnostics,
          err_at(
            "component_contract.collection.count_location_invalid",
            "count location fields conflict",
            path: path
          )
        )
      else
        diagnostics
      end

    if top? and ci.count_item_field_name != nil do
      add(
        diagnostics,
        err_at(
          "component_contract.collection.count_location_invalid",
          "root collection cannot use count_item_field_name",
          path: path
        )
      )
    else
      if nested? and ci.count_attr_name != nil do
        add(
          diagnostics,
          err_at(
            "component_contract.collection.count_location_invalid",
            "nested collection cannot use count_attr_name",
            path: path
          )
        )
      else
        diagnostics
      end
    end
  end

  defp validate_collection_locations(by_id, attrs_by_name, item_index, diagnostics) do
    Enum.reduce(by_id, diagnostics, fn {id, ci}, diagnostics ->
      path = "collection_inputs[#{id}]"
      top? = ci.public_attr_name != nil

      diagnostics =
        if top? do
          case Map.fetch(attrs_by_name, ci.public_attr_name) do
            {:ok, %Attr{type: :list}} ->
              diagnostics

            {:ok, _} ->
              add(
                diagnostics,
                err_at("component_contract.collection.attr_missing", "public attr must be :list",
                  path: path
                )
              )

            :error ->
              add(
                diagnostics,
                err_at(
                  "component_contract.collection.attr_missing",
                  "public_attr_name does not resolve",
                  path: path
                )
              )
          end
        else
          diagnostics
        end

      if top? and ci.count_attr_name != nil do
        validate_count_attr(diagnostics, attrs_by_name, ci.count_attr_name, path)
      else
        if not top? and ci.count_item_field_name != nil do
          validate_nested_count_field(diagnostics, by_id, item_index, ci, path)
        else
          diagnostics
        end
      end
    end)
  end

  defp validate_count_attr(diagnostics, attrs_by_name, name, path) do
    case Map.fetch(attrs_by_name, name) do
      {:ok, %Attr{type: :integer, validation: validation}} ->
        if non_negative_validation?(validation) do
          diagnostics
        else
          add(
            diagnostics,
            err_at(
              "component_contract.collection.count_location_invalid",
              "count attr requires non-negative validation",
              path: path
            )
          )
        end

      {:ok, _} ->
        add(
          diagnostics,
          err_at(
            "component_contract.collection.count_location_invalid",
            "count attr must be integer",
            path: path
          )
        )

      :error ->
        add(
          diagnostics,
          err_at("component_contract.collection.attr_missing", "count_attr_name does not resolve",
            path: path
          )
        )
    end
  end

  defp validate_nested_count_field(diagnostics, by_id, item_index, ci, path) do
    parent_id = ci.parent_collection_binding_id
    field_name = ci.count_item_field_name

    with {:parent, %CollectionInput{}} <- {:parent, Map.get(by_id, parent_id)},
         fields when is_map(fields) <- Map.get(item_index, parent_id, %{}),
         {:field, %ItemField{type: :integer, validation: validation}} <-
           {:field, Map.get(fields, field_name)} do
      if non_negative_validation?(validation) do
        diagnostics
      else
        add(
          diagnostics,
          err_at(
            "component_contract.collection.count_location_invalid",
            "count item field requires non-negative validation",
            path: path
          )
        )
      end
    else
      {:parent, _} ->
        add(
          diagnostics,
          err_at(
            "component_contract.collection.parent_missing",
            "parent collection input missing",
            path: path
          )
        )

      _ ->
        case Map.get(item_index, parent_id, %{}) |> Map.get(field_name) do
          %ItemField{type: :integer} ->
            add(
              diagnostics,
              err_at(
                "component_contract.collection.count_location_invalid",
                "count item field requires non-negative validation",
                path: path
              )
            )

          %ItemField{} ->
            add(
              diagnostics,
              err_at(
                "component_contract.collection.parent_field_type_invalid",
                "count item field must be integer",
                path: path
              )
            )

          _ ->
            add(
              diagnostics,
              err_at(
                "component_contract.collection.parent_field_missing",
                "count_item_field_name does not resolve",
                path: path
              )
            )
        end
    end
  end

  defp validate_collection_graph(by_id, _attrs_by_name, item_index, cyclic_ids, diagnostics) do
    Enum.reduce(by_id, diagnostics, fn {id, ci}, diagnostics ->
      path = "collection_inputs[#{id}]"
      nested? = ci.public_attr_name == nil

      diagnostics =
        if nested? do
          parent_id = ci.parent_collection_binding_id

          cond do
            parent_id == id ->
              add(
                diagnostics,
                err_at(
                  "component_contract.collection.parent_self",
                  "collection cannot be its own parent",
                  path: path
                )
              )

            MapSet.member?(cyclic_ids, id) ->
              add(
                diagnostics,
                err_at(
                  "component_contract.collection.parent_cycle",
                  "collection parent graph contains a cycle",
                  path: path
                )
              )

            not Map.has_key?(by_id, parent_id) ->
              add(
                diagnostics,
                err_at(
                  "component_contract.collection.parent_missing",
                  "parent collection input missing",
                  path: path
                )
              )

            true ->
              validate_nested_parent_field(diagnostics, by_id, item_index, ci, path)
          end
        else
          diagnostics
        end

      diagnostics
    end)
  end

  defp validate_nested_parent_field(diagnostics, by_id, item_index, ci, path) do
    parent_id = ci.parent_collection_binding_id
    field_name = ci.parent_item_field_name

    case Map.get(by_id, parent_id) do
      nil ->
        add(
          diagnostics,
          err_at(
            "component_contract.collection.parent_missing",
            "parent collection input missing",
            path: path
          )
        )

      _parent ->
        case Map.get(item_index, parent_id, %{}) |> Map.get(field_name) do
          %ItemField{type: :list} ->
            diagnostics

          %ItemField{} ->
            add(
              diagnostics,
              err_at(
                "component_contract.collection.parent_field_type_invalid",
                "parent item field must be :list",
                path: path
              )
            )

          _ ->
            add(
              diagnostics,
              err_at(
                "component_contract.collection.parent_field_missing",
                "parent_item_field_name does not resolve",
                path: path
              )
            )
        end
    end
  end

  defp collection_cycle_ids(by_id) when map_size(by_id) == 0, do: MapSet.new()

  defp collection_cycle_ids(by_id) do
    states = Map.new(Map.keys(by_id), &{&1, :unvisited})

    Enum.reduce(Map.keys(by_id), {MapSet.new(), states}, fn id, {cyclic, states} ->
      if Map.get(states, id) == :unvisited do
        walk_parent_chain(id, by_id, states, cyclic, [])
      else
        {cyclic, states}
      end
    end)
    |> elem(0)
  end

  defp walk_parent_chain(id, by_id, states, cyclic, stack) do
    case Map.get(states, id) do
      :visited ->
        {cyclic, states}

      :visiting ->
        {cyclic, states}

      :unvisited ->
        states = Map.put(states, id, :visiting)
        stack = [id | stack]

        case parent_id(Map.get(by_id, id)) do
          nil ->
            {cyclic, Map.put(states, id, :visited)}

          parent_id ->
            case Map.fetch(states, parent_id) do
              :error ->
                {cyclic, Map.put(states, id, :visited)}

              {:ok, :visited} ->
                {cyclic, Map.put(states, id, :visited)}

              {:ok, :visiting} ->
                members = cycle_suffix(stack, parent_id)
                cyclic = MapSet.union(cyclic, MapSet.new(members))
                states = mark_visited(states, members)
                {cyclic, Map.put(states, id, :visited)}

              {:ok, :unvisited} ->
                {cyclic, states} = walk_parent_chain(parent_id, by_id, states, cyclic, stack)
                {cyclic, Map.put(states, id, :visited)}
            end
        end
    end
  end

  defp parent_id(%CollectionInput{parent_collection_binding_id: pid}), do: pid
  defp parent_id(_), do: nil

  defp mark_visited(states, ids),
    do: Enum.reduce(ids, states, fn id, s -> Map.put(s, id, :visited) end)

  defp cycle_suffix(reversed_stack, cycle_start_id) do
    Enum.reduce_while(reversed_stack, [], fn node, acc ->
      if node == cycle_start_id, do: {:halt, [node | acc]}, else: {:cont, [node | acc]}
    end)
  end

  defp validate_item_fields(fields, path, diagnostics) when is_list(fields) do
    if proper_list?(fields) do
      Enum.reduce(fields, {%{}, diagnostics}, fn field, {by_name, diagnostics} ->
        case field do
          %ItemField{} = f ->
            idx = map_size(by_name)
            fpath = "#{path}[#{idx}]"
            diagnostics = validate_item_field(f, fpath, diagnostics)

            case Map.fetch(by_name, f.name) do
              {:ok, _} ->
                {by_name,
                 add(
                   diagnostics,
                   err_at(
                     "component_contract.item_field.name_duplicate",
                     "item field names must be unique",
                     path: fpath <> ".name"
                   )
                 )}

              :error ->
                {Map.put(by_name, f.name, f), diagnostics}
            end

          _ ->
            {by_name,
             add(
               diagnostics,
               err_at("component_contract.item_field.invalid", "expected ItemField struct",
                 path: path
               )
             )}
        end
      end)
    else
      validate_item_fields(nil, path, diagnostics)
    end
  end

  defp validate_item_fields(_, path, diagnostics) do
    {%{},
     add(
       diagnostics,
       err_at("component_contract.item_field.invalid", "item_fields must be a list", path: path)
     )}
  end

  defp validate_item_field(%ItemField{} = field, path, diagnostics) do
    diagnostics
    |> validate_public_name(field.name, path <> ".name")
    |> validate_phoenix_type(field.type, path <> ".type", :item_field)
    |> validate_required_default(field.required, field.default, path)
    |> validate_semantic_purpose(field.semantic_purpose, path)
    |> require_json_object(
      field.validation,
      "component_contract.metadata.invalid",
      "validation must be a JSON object",
      path <> ".validation"
    )
    |> require_json_object(
      field.accessibility,
      "component_contract.metadata.invalid",
      "accessibility must be a JSON object",
      path <> ".accessibility"
    )
    |> require_json_object(
      field.provenance,
      "component_contract.metadata.invalid",
      "provenance must be a JSON object",
      path <> ".provenance"
    )
    |> validate_json_default(field.default, path <> ".default")
  end

  defp validate_binding_projections(
         projections,
         attrs_by_name,
         slots_by_name,
         collection_by_id,
         item_index,
         diagnostics
       )
       when is_list(projections) do
    if proper_list?(projections) do
      Enum.reduce(Enum.with_index(projections), diagnostics, fn {projection, idx}, diagnostics ->
        path = "binding_projections[#{idx}]"

        case projection do
          %BindingProjection{} = p ->
            validate_binding_projection(
              p,
              path,
              attrs_by_name,
              slots_by_name,
              collection_by_id,
              item_index,
              diagnostics
            )

          _ ->
            add(
              diagnostics,
              err_at("component_contract.projection.invalid", "expected BindingProjection struct",
                path: path
              )
            )
        end
      end)
    else
      validate_binding_projections(
        nil,
        attrs_by_name,
        slots_by_name,
        collection_by_id,
        item_index,
        diagnostics
      )
    end
  end

  defp validate_binding_projections(_, _, _, _, _, diagnostics) do
    add(
      diagnostics,
      err("component_contract.projection.invalid", "binding_projections must be a list")
    )
  end

  defp validate_binding_projection(
         %BindingProjection{} = p,
         path,
         attrs_by_name,
         slots_by_name,
         collection_by_id,
         item_index,
         diagnostics
       ) do
    diagnostics
    |> validate_projection_enums(p, path)
    |> validate_projection_ids(p, path)
    |> validate_projection_shape(p, path)
    |> validate_projection_targets(
      p,
      path,
      attrs_by_name,
      slots_by_name,
      collection_by_id,
      item_index
    )
  end

  defp validate_projection_enums(diagnostics, p, path) do
    diagnostics
    |> then(fn d ->
      if p.source_binding_kind in BindingProjection.source_binding_kinds(),
        do: d,
        else:
          add(
            d,
            err_at(
              "component_contract.projection.source_kind_invalid",
              "invalid source_binding_kind",
              path: path
            )
          )
    end)
    |> then(fn d ->
      if p.projection_kind in BindingProjection.projection_kinds(),
        do: d,
        else:
          add(
            d,
            err_at("component_contract.projection.kind_invalid", "invalid projection_kind",
              path: path
            )
          )
    end)
  end

  defp validate_projection_ids(diagnostics, p, path) do
    diagnostics =
      Enum.reduce(
        [
          :public_attr_name,
          :public_slot_name,
          :source_collection_binding_id,
          :parent_collection_binding_id,
          :item_field_name,
          :parent_item_field_name
        ],
        diagnostics,
        fn field, acc ->
          validate_optional_artifact_string(
            acc,
            Map.fetch!(p, field),
            "component_contract.projection.binding_missing",
            path <> "." <> Atom.to_string(field)
          )
        end
      )

    if non_empty_string?(p.source_binding_id) and non_empty_string?(p.target_node_id) do
      diagnostics
    else
      add(
        diagnostics,
        err_at(
          "component_contract.projection.binding_missing",
          "source_binding_id and target_node_id are required",
          path: path
        )
      )
    end
  end

  defp validate_projection_shape(diagnostics, p, path) do
    case p.projection_kind do
      :scalar_attr ->
        require_shape(diagnostics, p, path, :value,
          attr: p.public_attr_name,
          forbid_collection: true
        )

      :collection_attr ->
        require_shape(diagnostics, p, path, :collection,
          attr: p.public_attr_name,
          collection: p.source_collection_binding_id
        )

      :collection_count_attr ->
        require_shape(diagnostics, p, path, :value,
          attr: p.public_attr_name,
          collection: p.source_collection_binding_id
        )

      :slot ->
        require_shape(diagnostics, p, path, :value,
          slot: p.public_slot_name,
          forbid_collection: true
        )

      :collection_item_field ->
        validate_collection_item_field_shape(diagnostics, p, path)

      _ ->
        diagnostics
    end
  end

  defp validate_collection_item_field_shape(diagnostics, p, path) do
    value_nested? =
      p.source_binding_kind == :value and p.source_collection_binding_id != nil and
        p.parent_collection_binding_id != nil and p.parent_item_field_name != nil and
        p.item_field_name == nil and p.public_attr_name == nil and p.public_slot_name == nil

    collection_nested? =
      p.source_binding_kind == :collection and p.source_collection_binding_id != nil and
        p.parent_collection_binding_id != nil and p.parent_item_field_name != nil and
        p.item_field_name == nil and p.public_attr_name == nil and p.public_slot_name == nil

    value_ordinary? =
      p.source_binding_kind == :value and p.item_field_name != nil and
        p.source_collection_binding_id != nil and
        p.parent_collection_binding_id == nil and p.parent_item_field_name == nil and
        p.public_attr_name == nil and p.public_slot_name == nil

    if value_nested? or collection_nested? or value_ordinary? do
      diagnostics
    else
      add(
        diagnostics,
        err_at(
          "component_contract.projection.target_shape_invalid",
          "invalid collection_item_field projection shape",
          path: path
        )
      )
    end
  end

  defp require_shape(diagnostics, p, path, kind, opts) do
    diagnostics
    |> then(fn d ->
      if p.source_binding_kind == kind,
        do: d,
        else:
          add(
            d,
            err_at(
              "component_contract.projection.target_shape_invalid",
              "source_binding_kind mismatch",
              path: path
            )
          )
    end)
    |> then(fn d ->
      cond do
        opts[:attr] != nil and p.public_attr_name == opts[:attr] and p.public_slot_name == nil ->
          d

        opts[:slot] != nil and p.public_slot_name == opts[:slot] and p.public_attr_name == nil ->
          d

        opts[:attr] == nil and opts[:slot] == nil ->
          d

        true ->
          add(
            d,
            err_at(
              "component_contract.projection.target_shape_invalid",
              "public target field mismatch",
              path: path
            )
          )
      end
    end)
    |> then(fn d ->
      if opts[:forbid_collection] == true and
           (p.source_collection_binding_id != nil or p.parent_collection_binding_id != nil or
              p.item_field_name != nil or p.parent_item_field_name != nil) do
        add(
          d,
          err_at(
            "component_contract.projection.target_shape_invalid",
            "forbidden collection reference fields",
            path: path
          )
        )
      else
        d
      end
    end)
    |> then(fn d ->
      if opts[:collection] != nil and p.source_collection_binding_id == opts[:collection] and
           p.parent_collection_binding_id == nil and p.item_field_name == nil and
           p.parent_item_field_name == nil and p.public_slot_name == nil do
        d
      else
        if opts[:collection] != nil do
          add(
            d,
            err_at(
              "component_contract.projection.target_shape_invalid",
              "collection projection field mismatch",
              path: path
            )
          )
        else
          d
        end
      end
    end)
  end

  defp validate_projection_targets(
         diagnostics,
         p,
         path,
         attrs_by_name,
         slots_by_name,
         collection_by_id,
         item_index
       ) do
    diagnostics =
      case p.projection_kind do
        :scalar_attr ->
          if Map.has_key?(attrs_by_name, p.public_attr_name),
            do: diagnostics,
            else:
              add(
                diagnostics,
                err_at(
                  "component_contract.projection.target_shape_invalid",
                  "public attr missing",
                  path: path
                )
              )

        :collection_attr ->
          diagnostics
          |> then(fn d ->
            if Map.has_key?(attrs_by_name, p.public_attr_name),
              do: d,
              else:
                add(
                  d,
                  err_at(
                    "component_contract.projection.target_shape_invalid",
                    "public attr missing",
                    path: path
                  )
                )
          end)
          |> then(fn d ->
            if Map.has_key?(collection_by_id, p.source_collection_binding_id),
              do: d,
              else:
                add(
                  d,
                  err_at(
                    "component_contract.projection.collection_ownership_mismatch",
                    "collection input missing",
                    path: path
                  )
                )
          end)

        :collection_count_attr ->
          diagnostics
          |> then(fn d ->
            if Map.has_key?(attrs_by_name, p.public_attr_name),
              do: d,
              else:
                add(
                  d,
                  err_at(
                    "component_contract.projection.target_shape_invalid",
                    "public attr missing",
                    path: path
                  )
                )
          end)
          |> then(fn d ->
            if Map.has_key?(collection_by_id, p.source_collection_binding_id),
              do: d,
              else:
                add(
                  d,
                  err_at(
                    "component_contract.projection.collection_ownership_mismatch",
                    "collection input missing",
                    path: path
                  )
                )
          end)

        :slot ->
          if Map.has_key?(slots_by_name, p.public_slot_name),
            do: diagnostics,
            else:
              add(
                diagnostics,
                err_at(
                  "component_contract.projection.target_shape_invalid",
                  "public slot missing",
                  path: path
                )
              )

        :collection_item_field ->
          validate_item_field_projection_targets(
            diagnostics,
            p,
            path,
            collection_by_id,
            item_index
          )

        _ ->
          diagnostics
      end

    diagnostics
  end

  defp validate_item_field_projection_targets(diagnostics, p, path, collection_by_id, item_index) do
    if not Map.has_key?(collection_by_id, p.source_collection_binding_id) do
      add(
        diagnostics,
        err_at(
          "component_contract.projection.collection_ownership_mismatch",
          "collection input missing",
          path: path
        )
      )
    else
      if p.item_field_name != nil do
        fields = Map.get(item_index, p.source_collection_binding_id, %{})

        if Map.has_key?(fields, p.item_field_name) do
          diagnostics
        else
          add(
            diagnostics,
            err_at("component_contract.projection.target_shape_invalid", "item field missing",
              path: path
            )
          )
        end
      else
        diagnostics
      end
    end
  end

  defp validate_public_name_conflicts(attrs_by_name, slots_by_name, diagnostics) do
    Enum.reduce(attrs_by_name, diagnostics, fn {name, _}, d ->
      if Map.has_key?(slots_by_name, name) do
        add(
          d,
          err_at(
            "component_contract.public_name.conflict",
            "attr and slot names must not conflict",
            path: name
          )
        )
      else
        d
      end
    end)
  end

  defp validate_intent_name(diagnostics, name, field) do
    if non_empty_string?(name) do
      if source_specific_name?(name) do
        add(
          diagnostics,
          err_at(
            "component_contract.public_name.source_specific",
            "intent uses source-specific vocabulary",
            path: field
          )
        )
      else
        diagnostics
      end
    else
      add(
        diagnostics,
        err_at("component_contract.identity.invalid", "#{field} must be a non-empty string",
          path: field
        )
      )
    end
  end

  defp validate_public_name(diagnostics, name, path) do
    cond do
      not non_empty_string?(name) ->
        add(
          diagnostics,
          err_at("component_contract.attr.invalid", "name must be a non-empty string", path: path)
        )

      not Regex.match?(@name_pattern, name) ->
        add(
          diagnostics,
          err_at("component_contract.attr.invalid", "name must be a valid public identifier",
            path: path
          )
        )

      source_specific_name?(name) ->
        add(
          diagnostics,
          err_at(
            "component_contract.public_name.source_specific",
            "name uses source-specific vocabulary",
            path: path
          )
        )

      true ->
        diagnostics
    end
  end

  defp validate_phoenix_type(diagnostics, type, path, kind \\ :attr) do
    allowed = if kind == :item_field, do: ItemField.phoenix_types(), else: Attr.phoenix_types()

    if type in allowed do
      diagnostics
    else
      code =
        if kind == :item_field,
          do: "component_contract.item_field.type_invalid",
          else: "component_contract.attr.type_invalid"

      add(diagnostics, err_at(code, "type is not supported", path: path))
    end
  end

  defp validate_required_default(diagnostics, required, default, path) do
    diagnostics
    |> validate_boolean_required_flag(required, path <> ".required")
    |> then(fn d ->
      if is_boolean(required) and required and default != nil do
        add(
          d,
          err_at(
            "component_contract.attr.default_conflict",
            "required attrs cannot have a default",
            path: path
          )
        )
      else
        d
      end
    end)
  end

  defp validate_boolean_required_flag(diagnostics, required, _path) when is_boolean(required),
    do: diagnostics

  defp validate_boolean_required_flag(diagnostics, _required, path) do
    add(
      diagnostics,
      err_at("component_contract.attr.invalid", "required must be a boolean", path: path)
    )
  end

  defp validate_semantic_purpose(diagnostics, purpose, path) do
    if non_empty_string?(purpose),
      do: diagnostics,
      else:
        add(
          diagnostics,
          err_at("component_contract.attr.invalid", "semantic_purpose is required", path: path)
        )
  end

  defp validate_json_default(diagnostics, default, path) do
    if match?({:ok, _}, Json.normalize(default)),
      do: diagnostics,
      else:
        add(
          diagnostics,
          err_at("component_contract.metadata.invalid", "default must be JSON-compatible",
            path: path
          )
        )
  end

  defp validate_stored_diagnostics(diagnostics, stored) when is_list(stored) do
    if proper_list?(stored) do
      Enum.reduce(stored, diagnostics, fn
        %Diagnostic{} = d, acc ->
          acc
          |> validate_stored_diagnostic_code(d.code)
          |> validate_stored_severity(d.severity)
          |> validate_stored_message(d.message)
          |> validate_optional_string(d.path)
          |> validate_optional_string(d.suggested_action)
          |> require_json_object(
            d.metadata,
            "component_contract.metadata.invalid",
            "diagnostic metadata must be a JSON object"
          )

        _, acc ->
          add(
            acc,
            err(
              "component_contract.metadata.invalid",
              "diagnostics must contain Diagnostic structs"
            )
          )
      end)
    else
      add(
        diagnostics,
        err("component_contract.metadata.invalid", "diagnostics must be a proper list")
      )
    end
  end

  defp validate_stored_diagnostics(diagnostics, _), do: diagnostics

  defp validate_stored_diagnostic_code(diagnostics, code) when is_binary(code) do
    if String.valid?(code) and String.starts_with?(code, "component_contract."),
      do: diagnostics,
      else:
        add(
          diagnostics,
          err(
            "component_contract.metadata.invalid",
            "diagnostic code must use component_contract prefix"
          )
        )
  end

  defp validate_stored_diagnostic_code(diagnostics, _),
    do:
      add(
        diagnostics,
        err("component_contract.metadata.invalid", "diagnostic code must be a string")
      )

  defp validate_stored_severity(diagnostics, severity) when severity in @diagnostic_severities,
    do: diagnostics

  defp validate_stored_severity(diagnostics, _),
    do:
      add(
        diagnostics,
        err("component_contract.metadata.invalid", "diagnostic severity is invalid")
      )

  defp validate_stored_message(diagnostics, message) do
    if non_empty_string?(message),
      do: diagnostics,
      else:
        add(
          diagnostics,
          err("component_contract.metadata.invalid", "diagnostic message is required")
        )
  end

  defp validate_optional_string(diagnostics, value) when is_nil(value), do: diagnostics

  defp validate_optional_string(diagnostics, value) do
    if valid_string?(value),
      do: diagnostics,
      else:
        add(
          diagnostics,
          err("component_contract.metadata.invalid", "diagnostic path must be a string or nil")
        )
  end

  defp validate_optional_artifact_string(diagnostics, nil, _code, _path), do: diagnostics

  defp validate_optional_artifact_string(diagnostics, value, code, path) do
    if valid_string?(value),
      do: diagnostics,
      else: add(diagnostics, err_at(code, "value must be a UTF-8 string or nil", path: path))
  end

  defp valid_string?(value), do: is_binary(value) and String.valid?(value)
  defp non_empty_string?(value), do: valid_string?(value) and value != ""
  defp proper_list?([]), do: true
  defp proper_list?([_head | tail]), do: proper_list?(tail)
  defp proper_list?(_tail), do: false

  defp source_specific_name?(name) do
    name in @banned_exact or
      String.starts_with?(name, "bricks_") or
      String.starts_with?(name, "wp_") or
      String.starts_with?(name, "element_")
  end

  def non_negative_validation?(validation) when is_map(validation) do
    case Map.get(validation, "min") do
      0 -> true
      n when is_number(n) and n > 0 -> true
      _ -> false
    end
  end

  def non_negative_validation?(_validation), do: false

  defp require_list(diagnostics, value, code, msg) do
    if proper_list?(value), do: diagnostics, else: add(diagnostics, err(code, msg))
  end

  defp require_json_object(diagnostics, value, code, message, path \\ nil) do
    if Json.object?(value) do
      diagnostics
    else
      if path,
        do: add(diagnostics, err_at(code, message, path: path)),
        else: add(diagnostics, err(code, message))
    end
  end

  defp finish([]), do: :ok

  defp finish(diagnostics) do
    {:error,
     diagnostics
     |> Enum.reverse()
     |> Enum.sort_by(fn d -> {d.path || "", d.code || "", d.message || ""} end)}
  end

  defp add(diagnostics, diagnostic), do: [diagnostic | diagnostics]

  defp err(code, message), do: Diagnostic.new(code: code, severity: :error, message: message)

  defp err_at(code, message, opts),
    do: Diagnostic.new([code: code, severity: :error, message: message] ++ opts)
end
