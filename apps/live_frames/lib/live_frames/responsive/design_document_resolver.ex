defmodule LiveFrames.Responsive.DesignDocumentResolver do
  @moduledoc """
  Binds unresolved Design IR responsive overrides to validated breakpoint authority.
  """

  alias LiveFrames.IR
  alias LiveFrames.IR.{DesignDocument, DesignNode, Diagnostic, ResponsiveOverride}
  alias LiveFrames.Responsive.BreakpointAuthority
  alias LiveFrames.Responsive.Resolution

  @spec resolve(DesignDocument.t(), BreakpointAuthority.t() | map()) ::
          {:ok, DesignDocument.t()} | {:error, Diagnostic.t()}
  def resolve(%DesignDocument{} = document, breakpoint_authority) do
    with :ok <- validate_document(document),
         {:ok, authority} <- coerce_authority(breakpoint_authority),
         {:ok, root_nodes} <- resolve_nodes(document.root_nodes, authority),
         resolved_document = %{document | root_nodes: root_nodes},
         :ok <- validate_document(resolved_document) do
      {:ok, resolved_document}
    end
  end

  def resolve(_document, _breakpoint_authority),
    do:
      {:error,
       diagnostic("design_document_resolver.input_invalid", "expected a DesignDocument", %{})}

  @spec has_responsive_overrides?(term()) :: boolean()
  def has_responsive_overrides?(%DesignDocument{root_nodes: root_nodes}) when is_list(root_nodes),
    do: Enum.any?(root_nodes, &node_has_responsive_overrides?/1)

  def has_responsive_overrides?(_document), do: false

  defp validate_document(document) do
    case IR.validate(document) do
      :ok ->
        :ok

      {:error, _diagnostics} ->
        {:error,
         diagnostic(
           "design_document_resolver.input_invalid",
           "DesignDocument failed IR validation",
           %{}
         )}
    end
  end

  defp coerce_authority(authority) do
    case BreakpointAuthority.coerce(authority) do
      {:ok, %BreakpointAuthority{} = validated} ->
        {:ok, validated}

      {:ok, nil} ->
        {:error,
         diagnostic(
           "design_document_resolver.authority_invalid",
           "breakpoint authority is required",
           %{}
         )}

      {:error, reason} ->
        {:error,
         diagnostic(
           "design_document_resolver.authority_invalid",
           "breakpoint authority failed validation",
           %{"reason" => Atom.to_string(reason)}
         )}
    end
  end

  defp resolve_nodes(nodes, authority) do
    Enum.reduce_while(nodes, {:ok, []}, fn node, {:ok, acc} ->
      case resolve_node(node, authority) do
        {:ok, resolved_node} -> {:cont, {:ok, [resolved_node | acc]}}
        {:error, _diagnostic} = error -> {:halt, error}
      end
    end)
    |> case do
      {:ok, reversed} -> {:ok, Enum.reverse(reversed)}
      {:error, _diagnostic} = error -> error
    end
  end

  defp resolve_node(%DesignNode{} = node, authority) do
    with {:ok, responsive} <- resolve_overrides(node, authority),
         {:ok, children} <- resolve_nodes(node.children, authority) do
      {:ok, %{node | responsive: responsive, children: children}}
    end
  end

  defp node_has_responsive_overrides?(%DesignNode{responsive: responsive, children: children}) do
    (is_map(responsive) and map_size(responsive) > 0) or
      (is_list(children) and Enum.any?(children, &node_has_responsive_overrides?/1))
  end

  defp node_has_responsive_overrides?(_node), do: false

  defp resolve_overrides(%DesignNode{} = node, authority) do
    Enum.reduce_while(node.responsive, {:ok, %{}}, fn {key, override}, {:ok, acc} ->
      case resolve_override(node.node_id, override, authority) do
        {:ok, resolved} -> {:cont, {:ok, Map.put(acc, key, resolved)}}
        {:error, _diagnostic} = error -> {:halt, error}
      end
    end)
  end

  defp resolve_override(
         node_id,
         %ResponsiveOverride{resolution_status: :unresolved} = override,
         authority
       ) do
    case BreakpointAuthority.lookup(authority, override.breakpoint_id, override.source_name) do
      {:ok, entry} ->
        case Resolution.bind(Resolution.new(node_id, override), entry) do
          {:ok, bound} ->
            {:ok,
             %{
               override
               | min_width: bound.authority.min_width,
                 max_width: bound.authority.max_width,
                 resolution_status: :resolved
             }}

          {:error, _reason} ->
            {:error,
             diagnostic(
               "design_document_resolver.binding_failed",
               "responsive override could not bind to breakpoint authority",
               override_metadata(node_id, override)
             )}
        end

      {:error, :authority_missing} ->
        {:error,
         diagnostic(
           "design_document_resolver.authority_missing",
           "no accepted breakpoint authority matches the unresolved override",
           override_metadata(node_id, override)
         )}

      {:error, :source_breakpoint_mismatch} ->
        {:error,
         diagnostic(
           "design_document_resolver.source_breakpoint_mismatch",
           "responsive source name does not match its breakpoint authority entry",
           override_metadata(node_id, override)
         )}
    end
  end

  defp resolve_override(
         node_id,
         %ResponsiveOverride{resolution_status: :resolved} = override,
         authority
       ) do
    case BreakpointAuthority.lookup(authority, override.breakpoint_id, override.source_name) do
      {:ok, entry} ->
        if override.min_width == entry.min_width and override.max_width == entry.max_width do
          {:ok, override}
        else
          {:error,
           diagnostic(
             "design_document_resolver.resolved_authority_conflict",
             "resolved responsive range conflicts with matching breakpoint authority",
             override_metadata(node_id, override)
           )}
        end

      {:error, :source_breakpoint_mismatch} ->
        {:error,
         diagnostic(
           "design_document_resolver.source_breakpoint_mismatch",
           "responsive source name does not match its breakpoint authority entry",
           override_metadata(node_id, override)
         )}

      {:error, :authority_missing} ->
        {:error,
         diagnostic(
           "design_document_resolver.authority_missing",
           "no accepted breakpoint authority matches the resolved override",
           override_metadata(node_id, override)
         )}
    end
  end

  defp override_metadata(node_id, override) do
    %{
      "breakpoint_id" => override.breakpoint_id,
      "node_id" => node_id,
      "source_name" => override.source_name
    }
  end

  defp diagnostic(code, message, metadata) do
    %Diagnostic{
      code: code,
      severity: :error,
      category: :schema,
      message: message,
      metadata: metadata
    }
  end
end
