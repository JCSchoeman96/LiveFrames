defmodule LiveFrames.Adapters.AutomaticCSS.FluidClamp do
  alias LiveFrames.Styling.Fluid.Domain
  alias LiveFrames.Styling.Fluid.Value

  @moduledoc """
  Evaluates Automatic.css `fluidClamp` / `fluid` relationships from proven
  TokenSet derived inputs.

  Authority: Automatic.css 4.0.1 `assets/scss/helpers/_functions.scss`
  (`fluidClamp/2`, `fluid/2`) plus size maps under modules/text and
  modules/spacing.
  """

  @root_px 16.0
  @domain_ref "layout.fluid.viewport.default"
  @supported_variables [
    "h1",
    "h2",
    "h3",
    "h4",
    "text-m",
    "text-l",
    "text-s",
    "space-xs",
    "space-s",
    "space-m",
    "space-l",
    "space-xl",
    "space-xxl",
    "section-space-m"
  ]

  @type reason :: :unsupported_projection | :invalid_projection

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

  @spec semantic_value(map()) :: {:ok, map()} | {:error, reason()}
  def semantic_value(%{"recipe" => "acss.clamp", "variable" => variable} = value)
      when is_binary(variable) do
    if variable in @supported_variables do
      project_semantics(variable, Map.get(value, "inputs"))
    else
      {:error, :unsupported_projection}
    end
  end

  def semantic_value(_value), do: {:error, :unsupported_projection}

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
  defp range("text-s", inputs), do: text_s_range(inputs)
  defp range("space-xs", inputs), do: spaced(inputs, -2)
  defp range("space-s", inputs), do: spaced(inputs, -1)
  defp range("space-m", inputs), do: spaced(inputs, 0)
  defp range("space-l", inputs), do: spaced(inputs, 1)
  defp range("space-xl", inputs), do: spaced(inputs, 2)
  defp range("space-xxl", inputs), do: spaced(inputs, 3)
  defp range("section-space-m", inputs), do: section_pair(inputs)
  defp range(_variable, _inputs), do: :error

  defp project_semantics(variable, inputs) when is_map(inputs) and not is_struct(inputs) do
    with :ok <- validate_projection_inputs(variable, inputs),
         {:ok, start_px, end_px} <- range(variable, inputs),
         projection <- fluid_value(start_px, end_px),
         :ok <- Value.validate(projection) do
      {:ok, projection}
    else
      _ -> {:error, :invalid_projection}
    end
  rescue
    _error -> {:error, :invalid_projection}
  end

  defp project_semantics(_variable, _inputs), do: {:error, :invalid_projection}

  defp validate_projection_inputs(variable, inputs) do
    with :ok <- Domain.validate(viewport_domain(inputs)),
         true <- valid_projection_scales?(variable, inputs) do
      :ok
    else
      _ -> {:error, :invalid_projection}
    end
  end

  defp viewport_domain(inputs) do
    %{
      "type" => "fluid_domain",
      "format_version" => "1.0.0",
      "input" => "viewport_width",
      "start" => %{"value" => inputs["viewport_min"], "unit" => "px"},
      "end" => %{"value" => inputs["viewport_max"], "unit" => "px"},
      "clamp_policy" => "bounded"
    }
  end

  defp valid_projection_scales?("section-space-m", _inputs), do: true

  defp valid_projection_scales?(variable, inputs) when variable in @supported_variables do
    with {:ok, mobile_scale} <- number(inputs["mobile_scale"]),
         {:ok, desktop_scale} <- number(inputs["desktop_scale"]) do
      mobile_scale > 0 and desktop_scale > 0
    else
      _ -> false
    end
  end

  defp fluid_value(start_px, end_px) do
    %{
      "type" => "fluid_value",
      "format_version" => "1.0.0",
      "domain_ref" => @domain_ref,
      "start_value" => %{"value" => start_px, "unit" => "px"},
      "end_value" => %{"value" => end_px, "unit" => "px"},
      "interpolation" => "linear"
    }
  end

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

  defp text_s_range(inputs) do
    with -1 <- scale_power(inputs),
         {:ok, mobile_base, desktop_base, mobile_scale, desktop_scale} <- scales(inputs),
         {:ok, default_mobile} <- scale_by(mobile_base, mobile_scale, -1),
         {:ok, default_desktop} <- scale_by(desktop_base, desktop_scale, -1) do
      mobile = endpoint_px(inputs["mobile_endpoint_override_px"], default_mobile)
      desktop = endpoint_px(inputs["desktop_endpoint_override_px"], default_desktop)

      if is_number(mobile) and is_number(desktop) do
        {:ok, mobile, desktop}
      else
        :error
      end
    else
      _ -> :error
    end
  end

  defp scale_power(%{"scale_power" => -1}), do: -1
  defp scale_power(_inputs), do: :error

  defp endpoint_px(value, _default) when is_number(value), do: value
  defp endpoint_px(_value, default) when is_number(default), do: default
  defp endpoint_px(_, _), do: :error

  defp spaced(inputs, power) do
    with {:ok, mobile_base, desktop_base, mobile_scale, desktop_scale} <- scales(inputs),
         true <- mobile_scale > 0 and desktop_scale > 0,
         {:ok, mobile} <- scale_by(mobile_base, mobile_scale, power),
         {:ok, desktop} <- scale_by(desktop_base, desktop_scale, power) do
      {:ok, mobile, desktop}
    else
      _ -> :error
    end
  end

  defp scale_by(value, _scale, 0), do: {:ok, value}

  defp scale_by(value, scale, power) when power > 0 do
    safely_scale(value, scale, 1..power, &Kernel.*/2)
  end

  defp scale_by(value, scale, power) when power < 0 do
    safely_scale(value, scale, 1..abs(power), &Kernel.//2)
  end

  defp safely_scale(value, scale, steps, operation) do
    {:ok, Enum.reduce(steps, value, fn _, current -> operation.(current, scale) end)}
  rescue
    ArithmeticError -> :error
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

  defp clamp_from_px(mobile_px, desktop_px, viewport_min_px, viewport_max_px) do
    with {:ok, viewport_min_px} <- number(viewport_min_px),
         {:ok, viewport_max_px} <- number(viewport_max_px),
         true <- viewport_max_px > viewport_min_px do
      mobile_rem = mobile_px / @root_px
      desktop_rem = desktop_px / @root_px
      vp_min = viewport_min_px / @root_px
      vp_max = viewport_max_px / @root_px
      slope = (desktop_rem - mobile_rem) / (vp_max - vp_min)
      slope_vw = slope * 100
      intercept = mobile_rem - slope * vp_min
      lower_bound = min(mobile_rem, desktop_rem)
      upper_bound = max(mobile_rem, desktop_rem)

      "clamp(#{format(lower_bound)}rem, calc(#{format(slope_vw)}vw + #{format(intercept)}rem), #{format(upper_bound)}rem)"
    else
      _ -> nil
    end
  rescue
    ArithmeticError -> nil
    ArgumentError -> nil
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
