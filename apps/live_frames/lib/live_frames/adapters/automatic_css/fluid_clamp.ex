defmodule LiveFrames.Adapters.AutomaticCSS.FluidClamp do
  @moduledoc """
  Evaluates Automatic.css `fluidClamp` / `fluid` relationships from proven
  TokenSet derived inputs.

  Authority: Automatic.css 4.0.1 `assets/scss/helpers/_functions.scss`
  (`fluidClamp/2`, `fluid/2`) plus size maps under modules/text and
  modules/spacing.
  """

  @root_px 16.0

  @spec css_expression(map()) :: String.t() | nil
  def css_expression(%{"recipe" => "acss.clamp", "variable" => variable, "inputs" => inputs})
      when is_map(inputs) do
    case range(variable, inputs) do
      {:ok, min_px, max_px} ->
        clamp_from_px(min_px, max_px, inputs["viewport_min"], inputs["viewport_max"])

      :error ->
        nil
    end
  end

  def css_expression(_value), do: nil

  @spec from_px_pair(number(), number(), number(), number()) :: String.t() | nil
  def from_px_pair(min_px, max_px, viewport_min_px, viewport_max_px)
      when is_number(min_px) and is_number(max_px) and is_number(viewport_min_px) and
             is_number(viewport_max_px) do
    clamp_from_px(min_px, max_px, viewport_min_px, viewport_max_px)
  end

  def from_px_pair(_, _, _, _), do: nil

  defp range("h1", inputs), do: scaled_heading(inputs, 3)
  defp range("h2", inputs), do: scaled_heading(inputs, 2)
  defp range("h3", inputs), do: scaled_heading(inputs, 1)
  defp range("h4", inputs), do: scaled_heading(inputs, 0)
  defp range("text-m", inputs), do: scaled_text(inputs, 0)
  defp range("text-l", inputs), do: scaled_text(inputs, 1)
  defp range("space-m", inputs), do: base_pair(inputs)
  defp range("space-xl", inputs), do: spaced(inputs, 2)
  defp range("section-space-m", inputs), do: section_pair(inputs)
  defp range(_variable, _inputs), do: :error

  defp scaled_heading(inputs, power) do
    with {:ok, mobile_base, desktop_base, mobile_scale, desktop_scale} <- scales(inputs) do
      {:ok, mobile_base * pow(mobile_scale, power), desktop_base * pow(desktop_scale, power)}
    end
  end

  defp scaled_text(inputs, power) do
    with {:ok, mobile_base, desktop_base, mobile_scale, desktop_scale} <- scales(inputs) do
      {:ok, mobile_base * pow(mobile_scale, power), desktop_base * pow(desktop_scale, power)}
    end
  end

  defp spaced(inputs, steps) when steps >= 1 do
    with {:ok, mobile_base, desktop_base, mobile_scale, desktop_scale} <- scales(inputs) do
      mobile =
        Enum.reduce(1..steps, mobile_base, fn _, value -> value * mobile_scale end)

      desktop =
        Enum.reduce(1..steps, desktop_base, fn _, value -> value * desktop_scale end)

      {:ok, mobile, desktop}
    end
  end

  defp section_pair(inputs) do
    with {:ok, mobile_base, desktop_base, _mobile_scale, _desktop_scale} <- scales(inputs),
         {:ok, mobile_adjustment} <- number(inputs["mobile_adjustment"]),
         {:ok, desktop_adjustment} <- number(inputs["desktop_adjustment"]) do
      {:ok, mobile_base * mobile_adjustment, desktop_base * desktop_adjustment}
    else
      _ -> :error
    end
  end

  defp base_pair(inputs) do
    with {:ok, mobile_base, desktop_base, _mobile_scale, _desktop_scale} <- scales(inputs) do
      {:ok, mobile_base, desktop_base}
    end
  end

  defp scales(inputs) do
    with {:ok, mobile_base} <- number(inputs["mobile_base"]),
         {:ok, desktop_base} <- number(inputs["desktop_base"]),
         {:ok, mobile_scale} <- number(inputs["mobile_scale"]),
         {:ok, desktop_scale} <- number(inputs["desktop_scale"]) do
      {:ok, mobile_base, desktop_base, mobile_scale, desktop_scale}
    else
      _ -> :error
    end
  end

  defp clamp_from_px(min_px, max_px, viewport_min_px, viewport_max_px) do
    with {:ok, viewport_min_px} <- number(viewport_min_px),
         {:ok, viewport_max_px} <- number(viewport_max_px),
         true <- viewport_max_px > viewport_min_px do
      min_rem = min_px / @root_px
      max_rem = max_px / @root_px
      vp_min = viewport_min_px / @root_px
      vp_max = viewport_max_px / @root_px
      slope = (max_rem - min_rem) / (vp_max - vp_min)
      slope_vw = slope * 100
      intercept = min_rem - slope * vp_min

      "clamp(#{format(min_rem)}rem, calc(#{format(slope_vw)}vw + #{format(intercept)}rem), #{format(max_rem)}rem)"
    else
      _ -> nil
    end
  end

  defp pow(_number, 0), do: 1

  defp pow(number, power) when power > 0,
    do: Enum.reduce(1..power, 1, fn _, acc -> acc * number end)

  defp number(value) when is_integer(value), do: {:ok, value * 1.0}
  defp number(value) when is_float(value), do: {:ok, value}
  defp number(_value), do: :error

  defp format(value) when is_float(value) do
    value
    |> :erlang.float_to_binary(decimals: 10)
    |> String.trim_trailing("0")
    |> String.trim_trailing(".")
  end
end
