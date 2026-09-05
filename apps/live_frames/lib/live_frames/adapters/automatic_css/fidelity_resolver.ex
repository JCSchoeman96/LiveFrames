defmodule LiveFrames.Adapters.AutomaticCSS.FidelityResolver do
  @moduledoc "The deliberately small Automatic.css compatibility surface for fidelity output."

  @behaviour LiveFrames.Fidelity.SourceResolver

  alias LiveFrames.Adapters.AutomaticCSS.FluidClamp

  @hints ~w(bg--ultra-dark btn--primary btn--outline)

  def hints, do: @hints

  @impl true
  def resolve(classes, token_set), do: resolve(classes, token_set, %{})

  @impl true
  def resolve(classes, token_set, context) when is_list(classes) and is_map(context) do
    tokens = token_set["tokens"] || %{}
    consumed_hints = Enum.filter(@hints, &(&1 in classes))

    declarations =
      Enum.flat_map(consumed_hints, &declarations_for(&1, tokens)) ++
        semantic_declarations(context, tokens)

    %{
      resolver_id: "automatic_css",
      declarations: declarations,
      consumed_hints: consumed_hints
    }
  end

  def declarations(classes, token_set) do
    resolve(classes, token_set).declarations
  end

  defp semantic_declarations(%{semantic_type: "section"}, tokens) do
    [
      keyword("display", "flex"),
      keyword("flex-direction", "column"),
      token("padding-block", "spacing.section.padding_block", tokens),
      gutter("padding-inline", tokens),
      token("gap", "spacing.container_gap", tokens)
    ]
  end

  defp semantic_declarations(%{semantic_type: "heading", tag: tag}, tokens)
       when tag in ~w(h1 h2 h3 h4 h5 h6) do
    [
      token("font-size", "typography.heading.scale.#{tag}", tokens),
      token("font-weight", "typography.heading.font_weight", tokens),
      token("line-height", "typography.heading.line_height", tokens)
    ]
  end

  defp semantic_declarations(_context, _tokens), do: []

  defp declarations_for("bg--ultra-dark", tokens) do
    [
      token("background-color", "color.background.ultra_dark", tokens),
      token("color", "color.background.ultra_dark.text", tokens),
      token("--lf-context-heading-color", "color.background.ultra_dark.heading", tokens)
    ]
  end

  defp declarations_for("btn--primary", tokens) do
    [
      token("background-color", "button.primary.background", tokens),
      token("color", "button.primary.text", tokens),
      token("border-color", "button.primary.border", tokens),
      token("border-width", "button.primary.border_width", tokens),
      token("border-style", "button.primary.border_style", tokens),
      token("border-radius", "button.primary.radius", tokens),
      token("padding-inline", "button.primary.padding_inline", tokens),
      token("padding-block", "button.primary.padding_block", tokens),
      token("min-width", "button.primary.min_width", tokens),
      token("font-size", "button.primary.font_size", tokens),
      token("font-weight", "button.primary.font_weight", tokens),
      token("line-height", "button.primary.line_height", tokens),
      state("&:hover", "background-color", "button.primary.background_hover", tokens),
      state("&:focus-visible", "outline-color", "button.primary.focus", tokens)
    ]
  end

  defp declarations_for("btn--outline", tokens) do
    [
      token("background-color", "button.primary.outline.background", tokens),
      token("color", "button.primary.outline.text", tokens),
      token("border-color", "button.primary.outline.border", tokens),
      state("&:hover", "background-color", "button.primary.outline.background_hover", tokens),
      state("&:hover", "border-color", "button.primary.outline.border_hover", tokens),
      state("&:hover", "color", "button.primary.outline.text_hover", tokens),
      state("&:focus-visible", "outline-color", "button.primary.outline.focus", tokens)
    ]
  end

  defp keyword(property, value),
    do: %{property: property, path: nil, value: value, selector: nil}

  defp gutter(property, tokens) do
    value =
      with %{"resolved_value" => min_raw} <- tokens["spacing.gutter.min"],
           %{"resolved_value" => max_raw} <- tokens["spacing.gutter.max"],
           %{"resolved_value" => vp_min_raw} <- tokens["layout.viewport.min"],
           %{"resolved_value" => vp_max_raw} <- tokens["layout.viewport.max"],
           {:ok, min_px} <- px_number(min_raw),
           {:ok, max_px} <- px_number(max_raw),
           {:ok, viewport_min} <- px_number(vp_min_raw),
           {:ok, viewport_max} <- px_number(vp_max_raw),
           css when is_binary(css) <-
             FluidClamp.from_px_pair(min_px, max_px, viewport_min, viewport_max) do
        css
      else
        _ -> nil
      end

    %{
      property: property,
      path: "spacing.gutter",
      value: if(safe_value?(value), do: value),
      selector: nil
    }
  end

  defp px_number(value) when is_integer(value), do: {:ok, value * 1.0}
  defp px_number(value) when is_float(value), do: {:ok, value}

  defp px_number(value) when is_binary(value) do
    case Regex.run(~r/^(-?(?:\d+(?:\.\d+)?|\.\d+))px$/i, value) do
      [_, number] -> {:ok, String.to_float(ensure_float(number))}
      _ -> :error
    end
  end

  defp px_number(_value), do: :error

  defp ensure_float(number) do
    if String.contains?(number, "."), do: number, else: number <> ".0"
  end

  defp token(property, path, tokens) do
    case tokens[path] do
      %{"metadata" => %{"css_expression" => value}} when is_binary(value) ->
        %{property: property, path: path, value: if(safe_value?(value), do: value), selector: nil}

      %{"resolved_value" => value} when is_binary(value) ->
        %{property: property, path: path, value: if(safe_value?(value), do: value), selector: nil}

      %{"resolved_value" => value} when is_integer(value) or is_float(value) ->
        value = to_string(value)
        %{property: property, path: path, value: if(safe_value?(value), do: value), selector: nil}

      %{"resolved_value" => %{"type" => "derived"} = derived} = token ->
        value = derived_token_css(token, derived)
        %{property: property, path: path, value: if(safe_value?(value), do: value), selector: nil}

      _ ->
        %{property: property, path: path, value: nil, selector: nil}
    end
  end

  defp state(selector, property, path, tokens),
    do: Map.put(token(property, path, tokens), :selector, selector)

  defp derived_token_css(token, derived) do
    cond do
      css = FluidClamp.css_expression(derived) ->
        css

      is_binary(token["source_expression"]) ->
        derived_css_value(token["source_expression"])

      is_binary(get_in(token, ["metadata", "variable"])) ->
        derived_css_value(token["metadata"]["variable"])

      is_binary(derived["variable"]) ->
        derived_css_value(derived["variable"])

      true ->
        nil
    end
  end

  defp derived_css_value(expression) when is_binary(expression),
    do: if(String.starts_with?(expression, "var("), do: expression, else: "var(--#{expression})")

  defp derived_css_value(_expression), do: nil

  defp safe_value?(nil), do: false

  defp safe_value?(value),
    do: not Regex.match?(~r/[{};]|url\s*\(\s*(?:https?:|\/\/|javascript:)/i, value)
end
