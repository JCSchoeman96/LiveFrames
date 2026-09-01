defmodule LiveFrames.Adapters.AutomaticCSS.FidelityResolver do
  @moduledoc "The deliberately small Automatic.css compatibility surface for fidelity output."

  @hints ~w(bg--ultra-dark btn--primary btn--outline)

  def hints, do: @hints

  def declarations(classes, token_set) do
    tokens = token_set["tokens"] || %{}

    classes
    |> Enum.filter(&(&1 in @hints))
    |> Enum.flat_map(&declarations_for(&1, tokens))
  end

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

  defp token(property, path, tokens) do
    case tokens[path] do
      %{"resolved_value" => value} when is_binary(value) ->
        %{property: property, path: path, value: if(safe_value?(value), do: value), selector: nil}

      %{"resolved_value" => value} when is_integer(value) or is_float(value) ->
        value = to_string(value)
        %{property: property, path: path, value: if(safe_value?(value), do: value), selector: nil}

      %{"resolved_value" => %{"type" => "derived"}, "source_expression" => expression} ->
        value = derived_css_value(expression)
        %{property: property, path: path, value: if(safe_value?(value), do: value), selector: nil}

      _ ->
        %{property: property, path: path, value: nil, selector: nil}
    end
  end

  defp state(selector, property, path, tokens),
    do: Map.put(token(property, path, tokens), :selector, selector)

  defp derived_css_value(expression) when is_binary(expression),
    do: if(String.starts_with?(expression, "var("), do: expression, else: "var(#{expression})")

  defp safe_value?(value),
    do: not Regex.match?(~r/[{};]|url\s*\(\s*(?:https?:|\/\/|javascript:)/i, value)
end
