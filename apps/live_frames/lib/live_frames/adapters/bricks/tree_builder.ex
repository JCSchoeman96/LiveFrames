defmodule LiveFrames.Adapters.Bricks.TreeBuilder do
  @moduledoc """
  Validates Bricks parent/child relationships and reconstructs a deterministic
  ordered tree without repairing contradictory source data.
  """

  alias LiveFrames.Adapters.Bricks.Component
  alias LiveFrames.Adapters.Bricks.Diagnostic
  alias LiveFrames.Adapters.Bricks.Element
  alias LiveFrames.Adapters.Bricks.Tree

  @root_markers [nil, 0, "0"]

  @spec build(Component.t()) :: {:ok, Tree.t(), [Diagnostic.t()]} | {:error, [Diagnostic.t()]}
  def build(%Component{elements: elements}) when is_list(elements) do
    if elements == [] do
      {:error, [diagnostic("bricks.tree.empty", "Resolved component has no elements")]}
    else
      build_non_empty(elements)
    end
  end

  def build(_component),
    do: {:error, [diagnostic("bricks.tree.invalid", "Component elements must be a list")]}

  defp build_non_empty(elements) do
    {elements_by_id, source_order, index_diagnostics} = index_elements(elements)

    if index_diagnostics != [] do
      {:error, sort_diagnostics(index_diagnostics)}
    else
      children_by_id = Map.new(elements, fn element -> {element.id, element.children} end)
      parent_by_id = Map.new(elements, fn element -> {element.id, element.parent} end)

      diagnostics =
        parent_diagnostics(elements, elements_by_id) ++
          child_diagnostics(elements, elements_by_id) ++
          reciprocity_diagnostics(elements, elements_by_id) ++
          cycle_diagnostics(elements, parent_by_id)

      roots = Enum.filter(elements, &root_parent?(&1.parent)) |> Enum.map(& &1.id)

      diagnostics =
        if roots == [] and elements != [] do
          diagnostics ++ [diagnostic("bricks.tree.root_missing", "Tree has no root element")]
        else
          diagnostics
        end

      diagnostics =
        if length(roots) > 1 do
          diagnostics ++
            [
              diagnostic("bricks.tree.multiple_roots", "Tree contains multiple roots",
                severity: :warning,
                metadata: %{"root_ids" => roots}
              )
            ]
        else
          diagnostics
        end

      tree = %Tree{
        elements: elements_by_id,
        ordered_elements: elements,
        root_ids: roots,
        children_by_id: children_by_id,
        parent_by_id: parent_by_id,
        source_order: source_order
      }

      if Enum.any?(diagnostics, &(&1.severity in [:error, :fatal])) do
        {:error, sort_diagnostics(diagnostics)}
      else
        {:ok, tree, sort_diagnostics(diagnostics)}
      end
    end
  end

  defp index_elements(elements) do
    Enum.with_index(elements)
    |> Enum.reduce({%{}, [], []}, fn
      {%Element{id: id} = element, index}, {elements_by_id, source_order, diagnostics}
      when is_binary(id) and byte_size(id) > 0 ->
        if Map.has_key?(elements_by_id, id) do
          {elements_by_id, source_order,
           diagnostics ++
             [
               diagnostic("bricks.element.duplicate", "Element ID is duplicated",
                 source_id: id,
                 source_path: "elements[#{index}].id"
               )
             ]}
        else
          {Map.put(elements_by_id, id, element), source_order ++ [id], diagnostics}
        end

      {element, index}, {elements_by_id, source_order, diagnostics} ->
        element_id = if is_map(element), do: Map.get(element, :id), else: nil

        {elements_by_id, source_order,
         diagnostics ++
           [
             diagnostic("bricks.element.invalid", "Element ID must be a non-empty string",
               source_path: "elements[#{index}].id",
               raw_value: element_id
             )
           ]}
    end)
  end

  defp parent_diagnostics(elements, elements_by_id) do
    Enum.flat_map(elements, fn element ->
      cond do
        root_parent?(element.parent) ->
          []

        is_binary(element.parent) and Map.has_key?(elements_by_id, element.parent) ->
          []

        true ->
          [
            diagnostic("bricks.parent.missing", "Element parent does not exist",
              source_id: element.id,
              raw_value: element.parent
            )
          ]
      end
    end)
  end

  defp child_diagnostics(elements, elements_by_id) do
    Enum.flat_map(elements, fn element ->
      cond do
        not is_list(element.children) ->
          [
            diagnostic("bricks.element.invalid", "Element children must be a list",
              source_id: element.id,
              raw_value: element.children
            )
          ]

        true ->
          duplicate_diagnostics(element) ++
            Enum.flat_map(element.children, fn child_id ->
              if is_binary(child_id) and Map.has_key?(elements_by_id, child_id) do
                []
              else
                [
                  diagnostic("bricks.child.missing", "Element child does not exist",
                    source_id: element.id,
                    raw_value: child_id
                  )
                ]
              end
            end)
      end
    end)
  end

  defp duplicate_diagnostics(element) do
    if length(element.children) == length(Enum.uniq(element.children)) do
      []
    else
      [
        diagnostic("bricks.tree.duplicate_child", "Element declares a child more than once",
          source_id: element.id,
          raw_value: element.children
        )
      ]
    end
  end

  defp reciprocity_diagnostics(elements, elements_by_id) do
    parent_side =
      Enum.flat_map(elements, fn element ->
        if root_parent?(element.parent) do
          []
        else
          case Map.fetch(elements_by_id, element.parent) do
            {:ok, parent} ->
              if Enum.count(parent.children, &(&1 == element.id)) == 1 do
                []
              else
                [
                  diagnostic(
                    "bricks.tree.reciprocity",
                    "Element parent does not declare the element as a child",
                    source_id: element.id,
                    metadata: %{"parent_id" => element.parent}
                  )
                ]
              end

            :error ->
              []
          end
        end
      end)

    child_side =
      Enum.flat_map(elements, fn element ->
        Enum.flat_map(element.children, fn child_id ->
          case Map.fetch(elements_by_id, child_id) do
            {:ok, child} ->
              if child.parent == element.id do
                []
              else
                [
                  diagnostic(
                    "bricks.tree.reciprocity",
                    "Element child points to a different parent",
                    source_id: element.id,
                    metadata: %{"child_id" => child_id, "actual_parent" => child.parent}
                  )
                ]
              end

            :error ->
              []
          end
        end)
      end)

    parent_side ++ child_side
  end

  defp cycle_diagnostics(elements, parent_by_id) do
    elements
    |> Enum.map(& &1.id)
    |> Enum.flat_map(fn id ->
      case parent_cycle(id, parent_by_id, MapSet.new(), []) do
        {:cycle, cycle} ->
          [
            diagnostic("bricks.tree.cycle", "Element parent relationships contain a cycle",
              source_id: id,
              metadata: %{"cycle" => cycle}
            )
          ]

        :ok ->
          []
      end
    end)
    |> Enum.uniq_by(fn diagnostic -> {diagnostic.code, diagnostic.metadata["cycle"]} end)
  end

  defp parent_cycle(id, parent_by_id, visited, path) do
    cond do
      MapSet.member?(visited, id) ->
        {:cycle, Enum.reverse([id | path])}

      true ->
        case Map.get(parent_by_id, id) do
          parent when parent in @root_markers ->
            :ok

          parent when is_binary(parent) ->
            if Map.has_key?(parent_by_id, parent) do
              parent_cycle(parent, parent_by_id, MapSet.put(visited, id), [id | path])
            else
              :ok
            end

          _ ->
            :ok
        end
    end
  end

  defp root_parent?(parent), do: parent in @root_markers

  defp diagnostic(code, message, opts \\ []),
    do: Diagnostic.new([code: code, message: message] ++ opts)

  defp sort_diagnostics(diagnostics) do
    Enum.sort_by(diagnostics, fn diagnostic ->
      {diagnostic.code || "", diagnostic.source_path || "", diagnostic.source_id || "",
       diagnostic.message || ""}
    end)
  end
end
