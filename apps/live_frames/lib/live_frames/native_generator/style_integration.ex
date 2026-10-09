defmodule LiveFrames.NativeGenerator.StyleIntegration do
  @moduledoc false

  alias LiveFrames.ComponentContract
  alias LiveFrames.ComponentizationPlan
  alias LiveFrames.IR.DesignDocument
  alias LiveFrames.IR.DesignNode
  alias LiveFrames.IR.StyleValue
  alias LiveFrames.NativeGenerator.Diagnostic
  alias LiveFrames.NativeGenerator.NodeStyleIdentity
  alias LiveFrames.NativeGenerator.StylesheetRenderer

  @locus_gap_code "native_generator.styling.style_locus_authority_gap"
  @primary_variant_gap_code "native_generator.styling.primary_action_variant_authority_gap"
  @primary_precedence_gap_code "native_generator.styling.primary_action_style_precedence_gap"

  @primary_base_tokens %{
    "background-color" => "button.primary.background",
    "color" => "button.primary.text",
    "border-color" => "button.primary.border",
    "border-width" => "button.primary.border_width",
    "border-style" => "button.primary.border_style",
    "border-radius" => "button.primary.radius",
    "padding-inline" => "button.primary.padding_inline",
    "padding-block" => "button.primary.padding_block",
    "min-width" => "button.primary.min_width",
    "font-size" => "button.primary.font_size",
    "font-weight" => "button.primary.font_weight",
    "line-height" => "button.primary.line_height"
  }

  @spec build(ComponentContract.t(), ComponentizationPlan.t(), DesignDocument.t()) ::
          {:ok, map()} | {:error, :generation_blocked, [Diagnostic.t()]}
  def build(
        %ComponentContract{} = contract,
        %ComponentizationPlan{} = plan,
        %DesignDocument{} = doc
      ) do
    package_class = LiveFrames.NativeGenerator.Renderer.package_root_class(contract)

    with {:ok, identity} <- identity_index(doc, package_class),
         {:ok, boundary_node} <- boundary_node(plan.boundary_node_id, identity.nodes_by_id),
         {:ok, styles, classes} <-
           collect_styles(boundary_node, plan, identity.private_class_by_id),
         {:ok, css} <- render_styles(styles),
         {:ok, stylesheet_path} <- stylesheet_path(contract) do
      {:ok,
       %{
         private_class_by_id: classes,
         nodes_by_id: identity.nodes_by_id,
         stylesheet_content: css,
         stylesheet_path: stylesheet_path
       }}
    else
      {:error, %Diagnostic{} = diagnostic} -> blocked(diagnostic)
      {:error, :generation_blocked, _diagnostics} = error -> error
      {:error, reason} -> blocked(style_diagnostic(reason))
    end
  end

  defp identity_index(doc, package_class) do
    case NodeStyleIdentity.build(doc, package_class) do
      {:ok, identity} -> {:ok, identity}
      {:error, diagnostic} -> {:error, diagnostic}
    end
  end

  defp boundary_node(boundary_id, nodes_by_id) do
    case Map.fetch(nodes_by_id, boundary_id) do
      {:ok, node} -> {:ok, node}
      :error -> {:error, :boundary_missing}
    end
  end

  defp collect_styles(boundary_node, plan, private_class_by_id) do
    slot_targets =
      plan.render_projections
      |> Enum.filter(&(&1.render_role == :subtree_slot))
      |> MapSet.new(& &1.target_node_id)

    case collect_node_styles(boundary_node, plan, slot_targets, private_class_by_id, {[], %{}}) do
      {:ok, {rendered, classes}} -> {:ok, Enum.reverse(rendered), classes}
      {:error, diagnostic} -> {:error, diagnostic}
    end
  end

  defp collect_node_styles(node, plan, slot_targets, private_class_by_id, acc) do
    if MapSet.member?(slot_targets, node.node_id) do
      {:ok, acc}
    else
      with {:ok, next_acc} <-
             collect_node_style(node, plan.boundary_node_id, private_class_by_id, acc),
           {:ok, descendant_acc} <-
             collect_child_styles(
               node.children,
               plan,
               slot_targets,
               private_class_by_id,
               next_acc
             ) do
        {:ok, descendant_acc}
      end
    end
  end

  defp collect_child_styles(children, plan, slot_targets, private_class_by_id, acc) do
    Enum.reduce_while(children, {:ok, acc}, fn child, {:ok, child_acc} ->
      case collect_node_styles(child, plan, slot_targets, private_class_by_id, child_acc) do
        {:ok, next_acc} -> {:cont, {:ok, next_acc}}
        {:error, diagnostic} -> {:halt, {:error, diagnostic}}
      end
    end)
  end

  defp collect_node_style(node, boundary_id, private_class_by_id, {rendered, classes}) do
    case node_style(node) do
      {:ok, base_styles, pseudo_styles} ->
        responsive = responsive_overrides(node.responsive)
        styled? = node.styles != %{} or responsive != [] or pseudo_styles != %{}
        root? = node.node_id == boundary_id

        cond do
          figure_image?(node) and styled? ->
            {:error, style_locus_gap(node.node_id)}

          true ->
            class = Map.fetch!(private_class_by_id, node.node_id)

            classes =
              if root? or styled?, do: Map.put(classes, node.node_id, class), else: classes

            rendered =
              if styled?,
                do: [{class, base_styles, responsive, pseudo_styles} | rendered],
                else: rendered

            {:ok, {rendered, classes}}
        end

      {:error, diagnostic} ->
        {:error, diagnostic}
    end
  end

  defp node_style(%DesignNode{} = node) do
    with {:ok, action_styles, pseudo_styles} <- primary_action_styles(node),
         :ok <- no_base_collisions(node.styles, action_styles) do
      {:ok, Map.merge(node.styles, action_styles), pseudo_styles}
    end
  end

  defp primary_action_styles(%DesignNode{semantic_type: "button", attributes: attrs}) do
    if Map.get(attrs, "style") == "primary" do
      cond do
        Map.get(attrs, "outline") in [true, "true"] ->
          {:error,
           diagnostic(
             @primary_variant_gap_code,
             "Primary button outline variant authority is unresolved"
           )}

        true ->
          base =
            Map.new(@primary_base_tokens, fn {property, path} ->
              {property, StyleValue.token_ref(path)}
            end)

          {:ok, base,
           %{
             hover: %{
               "background-color" => StyleValue.token_ref("button.primary.background_hover")
             },
             focus_visible: %{
               "outline-color" => StyleValue.token_ref("button.primary.focus"),
               "outline-style" => StyleValue.keyword("solid"),
               "outline-width" => StyleValue.literal("2px"),
               "outline-offset" => StyleValue.literal("2px")
             }
           }}
      end
    else
      {:ok, %{}, %{}}
    end
  end

  defp primary_action_styles(_node), do: {:ok, %{}, %{}}

  defp no_base_collisions(styles, action_styles) do
    if MapSet.size(
         MapSet.intersection(MapSet.new(Map.keys(styles)), MapSet.new(Map.keys(action_styles)))
       ) == 0 do
      :ok
    else
      {:error,
       diagnostic(
         @primary_precedence_gap_code,
         "Primary action and normalized base styles overlap"
       )}
    end
  end

  defp responsive_overrides(responsive) when is_map(responsive), do: Map.values(responsive)
  defp responsive_overrides(responsive) when is_list(responsive), do: responsive
  defp responsive_overrides(nil), do: []
  defp responsive_overrides(_), do: [:invalid_responsive_authority]

  defp render_styles(styles) do
    Enum.reduce_while(styles, {:ok, []}, fn {class, base, responsive, pseudos}, {:ok, acc} ->
      with {:ok, css} <- StylesheetRenderer.render(class, base, responsive),
           {:ok, pseudo_css} <- render_pseudos(class, pseudos) do
        content =
          [css, pseudo_css]
          |> Enum.reject(&(&1 == ""))
          |> Enum.map(&String.trim_trailing/1)
          |> Enum.join("\n\n")

        {:cont, {:ok, [content | acc]}}
      else
        {:error, diagnostic} -> {:halt, {:error, diagnostic}}
      end
    end)
    |> case do
      {:ok, blocks} ->
        css =
          blocks
          |> Enum.reverse()
          |> Enum.reject(&(&1 == ""))
          |> Enum.join("\n\n")

        {:ok, trailing_newline(css)}

      {:error, diagnostic} ->
        {:error, diagnostic}
    end
  end

  defp render_pseudos(class, pseudos) do
    Enum.reduce_while([:hover, :focus_visible], {:ok, []}, fn pseudo, {:ok, acc} ->
      case Map.fetch(pseudos, pseudo) do
        {:ok, styles} ->
          case StylesheetRenderer.render_pseudo(class, pseudo, styles) do
            {:ok, ""} -> {:cont, {:ok, acc}}
            {:ok, css} -> {:cont, {:ok, [css | acc]}}
            {:error, diagnostic} -> {:halt, {:error, diagnostic}}
          end

        :error ->
          {:cont, {:ok, acc}}
      end
    end)
    |> case do
      {:ok, blocks} ->
        {:ok,
         blocks
         |> Enum.reverse()
         |> Enum.map(&String.trim_trailing/1)
         |> Enum.join("\n\n")}

      {:error, diagnostic} ->
        {:error, diagnostic}
    end
  end

  defp trailing_newline(""), do: ""
  defp trailing_newline(css), do: css <> "\n"

  defp stylesheet_path(%ComponentContract{category: category, module_intent: intent}) do
    directory =
      case category do
        :section -> "sections/"
        :component -> ""
        :pattern -> "patterns/"
        :primitive -> "primitives/"
        _ -> nil
      end

    if is_binary(directory) and is_binary(intent) do
      {:ok, "assets/css/components/" <> directory <> intent <> ".css"}
    else
      {:error, :invalid_stylesheet_authority}
    end
  end

  defp figure_image?(%DesignNode{semantic_type: "image", attributes: attrs}),
    do: Map.get(attrs, "tag") == "figure"

  defp figure_image?(_node), do: false

  defp style_locus_gap(node_id),
    do:
      diagnostic(@locus_gap_code, "Image styles cannot be assigned to a proven native element", %{
        node_id: node_id
      })

  defp style_diagnostic(reason),
    do:
      Diagnostic.error(
        "native_generator.styling.integration_failed",
        "Native styling input could not be integrated",
        %{reason: reason}
      )

  defp diagnostic(code, message, metadata \\ %{}), do: Diagnostic.error(code, message, metadata)

  defp blocked(diagnostic), do: {:error, :generation_blocked, [diagnostic]}
end
