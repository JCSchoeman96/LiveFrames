defmodule LiveFrames.Adapters.Bricks.Resolver do
  @moduledoc """
  Resolves a copied-content proxy to exactly one Bricks component.
  """

  alias LiveFrames.Adapters.Bricks.Diagnostic
  alias LiveFrames.Adapters.Bricks.Document
  alias LiveFrames.Adapters.Bricks.Element

  @spec resolve(Document.t(), keyword() | map()) ::
          {:ok, term(), term(), [Diagnostic.t()]} | {:error, [Diagnostic.t()]}
  def resolve(document, opts \\ [])

  def resolve(%Document{} = document, opts) do
    component_id = option(opts, :component_id)
    proxies = ordered_proxies(document)

    with {:ok, proxy} <- select_proxy(proxies, component_id),
         {:ok, component} <- fetch_component(document, proxy.cid),
         :ok <- validate_component(component) do
      {:ok, proxy, component, []}
    else
      {:error, diagnostics} when is_list(diagnostics) -> {:error, diagnostics}
      {:error, diagnostic} -> {:error, [diagnostic]}
    end
  end

  def resolve(_document, _opts),
    do: {:error, [diagnostic("bricks.source.invalid", "Cannot resolve a non-Bricks document")]}

  defp ordered_proxies(document) do
    order = Map.get(document, :content_proxy_order, [])

    if order == [] do
      document.content_proxies |> Map.values() |> Enum.sort_by(& &1.id)
    else
      Enum.flat_map(order, fn id ->
        case Map.fetch(document.content_proxies, id) do
          {:ok, proxy} -> [proxy]
          :error -> []
        end
      end)
    end
  end

  defp select_proxy([], _component_id),
    do:
      {:error,
       diagnostic("bricks.component.missing", "No copied-content component proxy was found")}

  defp select_proxy(proxies, component_id) when is_binary(component_id) do
    matches = Enum.filter(proxies, &(&1.cid == component_id))

    case matches do
      [proxy] ->
        {:ok, proxy}

      [] ->
        {:error,
         diagnostic("bricks.component.missing", "Requested component proxy was not found",
           source_id: component_id
         )}

      _ ->
        {:error,
         diagnostic(
           "bricks.component.ambiguous",
           "Requested component ID resolves to multiple proxies",
           source_id: component_id
         )}
    end
  end

  defp select_proxy(proxies, nil) do
    unique_cids = proxies |> Enum.map(& &1.cid) |> Enum.uniq()

    case {unique_cids, proxies} do
      {[cid], [proxy]} ->
        if proxy.cid == cid,
          do: {:ok, proxy},
          else:
            {:error, diagnostic("bricks.component.missing", "Copied-content proxy is invalid")}

      {[], _} ->
        {:error,
         diagnostic("bricks.component.missing", "No copied-content component proxy was found")}

      _ ->
        {:error,
         diagnostic(
           "bricks.component.ambiguous",
           "Multiple copied-content component proxies require explicit selection"
         )}
    end
  end

  defp select_proxy(_proxies, _component_id),
    do:
      {:error, diagnostic("bricks.component.missing", "Requested component ID must be a string")}

  defp fetch_component(document, cid) do
    case Map.fetch(document.components, cid) do
      {:ok, component} ->
        {:ok, component}

      :error ->
        {:error,
         diagnostic(
           "bricks.component.missing",
           "Copied-content proxy references a missing component",
           source_id: cid
         )}
    end
  end

  defp validate_component(%{elements: elements}) when is_list(elements) do
    if Enum.all?(elements, &match?(%Element{}, &1)) do
      :ok
    else
      {:error,
       diagnostic("bricks.component.invalid", "Resolved component contains malformed elements")}
    end
  end

  defp validate_component(_component),
    do:
      {:error,
       diagnostic("bricks.component.invalid", "Resolved component elements are malformed")}

  defp option(opts, key) when is_list(opts), do: Keyword.get(opts, key)
  defp option(opts, key) when is_map(opts), do: Map.get(opts, key)
  defp option(_opts, _key), do: nil

  defp diagnostic(code, message, opts \\ []),
    do: Diagnostic.new([code: code, message: message] ++ opts)
end
