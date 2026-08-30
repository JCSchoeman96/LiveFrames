defmodule LiveFrames.Adapters.Bricks.ClassResolver do
  @moduledoc """
  Resolves source/global class references while retaining their provenance.
  """

  alias LiveFrames.Adapters.Bricks.Diagnostic
  alias LiveFrames.Adapters.Bricks.Document
  alias LiveFrames.Adapters.Bricks.Tree

  @spec resolve(Tree.t(), Document.t()) ::
          {:ok, map(), [Diagnostic.t()]} | {:error, [Diagnostic.t()]}
  def resolve(%Tree{} = tree, %Document{} = document) do
    {elements, diagnostics} =
      Enum.reduce(tree.ordered_elements, {%{}, []}, fn element, {elements, diagnostics} ->
        {class_ids, class_id_diagnostics} = class_ids(element)

        {class_refs, class_names, class_settings, class_diagnostics} =
          Enum.reduce(class_ids, {[], [], %{}, []}, fn class_id,
                                                       {refs, names, settings, diagnostics} ->
            case Map.fetch(document.global_classes, class_id) do
              {:ok, class} ->
                ref = %{
                  id: class.id,
                  name: class.name,
                  category: class.category,
                  status: :resolved,
                  settings: class.settings,
                  raw: class.raw
                }

                {refs ++ [ref], names ++ [class.name], Map.merge(settings, class.settings),
                 diagnostics}

              :error ->
                ref = %{id: class_id, name: nil, category: nil, status: :unresolved, raw: nil}

                diagnostic =
                  Diagnostic.new(
                    code: "bricks.class.missing",
                    severity: :warning,
                    source_id: element.id,
                    source_path: "#{element.id}.settings._cssGlobalClasses",
                    raw_value: class_id,
                    message:
                      "Element references a global class that is absent from the copied payload",
                    metadata: %{"class_id" => class_id}
                  )

                fallback_name =
                  if safe_class_name?(class_id), do: class_id, else: "bricks-source-class"

                {refs ++ [ref], names ++ [fallback_name], settings, diagnostics ++ [diagnostic]}
            end
          end)

        {class_names, semantic_names} = add_button_classes(element, class_names)
        source_settings = Map.drop(element.settings, ["_cssGlobalClasses"])

        resolved = %{
          element: element,
          class_ids: class_ids,
          class_names: class_names,
          class_refs: class_refs,
          settings: Map.merge(class_settings, source_settings),
          source_settings: source_settings,
          semantic_classes: semantic_names
        }

        {Map.put(elements, element.id, resolved),
         diagnostics ++ class_id_diagnostics ++ class_diagnostics}
      end)

    {:ok, %{tree: tree, elements: elements}, sort_diagnostics(diagnostics)}
  end

  def resolve(_tree, _document),
    do:
      {:error,
       [
         Diagnostic.new(
           code: "bricks.class.invalid",
           message: "Cannot resolve classes without a Bricks tree and document"
         )
       ]}

  defp class_ids(element) do
    case Map.get(element.settings, "_cssGlobalClasses", []) do
      ids when is_list(ids) ->
        if Enum.all?(ids, &(is_binary(&1) and byte_size(&1) > 0)) do
          {ids, []}
        else
          {[],
           [
             Diagnostic.new(
               code: "bricks.class.invalid",
               severity: :warning,
               source_id: element.id,
               message: "Global class references must be non-empty strings",
               raw_value: ids
             )
           ]}
        end

      value ->
        {[],
         [
           Diagnostic.new(
             code: "bricks.class.invalid",
             severity: :warning,
             source_id: element.id,
             message: "Global class references must be a list",
             raw_value: value
           )
         ]}
    end
  end

  defp add_button_classes(%{name: "button", settings: settings}, class_names) do
    source_count = length(class_names)
    style = Map.get(settings, "style")

    class_names =
      if is_binary(style) and safe_class_name?(style),
        do: append_unless_present(class_names, style),
        else: class_names

    class_names =
      if Map.get(settings, "outline") == true,
        do: append_unless_present(class_names, "btn--outline"),
        else: class_names

    {class_names, Enum.drop(class_names, source_count)}
  end

  defp add_button_classes(_element, class_names), do: {class_names, []}

  defp append_unless_present(values, value),
    do: if(value in values, do: values, else: values ++ [value])

  defp safe_class_name?(value),
    do: is_binary(value) and Regex.match?(~r/^[A-Za-z_][A-Za-z0-9_-]*$/, value)

  defp sort_diagnostics(diagnostics) do
    Enum.sort_by(diagnostics, fn diagnostic ->
      {diagnostic.code || "", diagnostic.source_path || "", diagnostic.source_id || "",
       diagnostic.message || ""}
    end)
  end
end
