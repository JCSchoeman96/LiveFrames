defmodule LiveFrames.Adapters.AutomaticCSS.IconTokens do
  @moduledoc false

  alias LiveFrames.Adapters.AutomaticCSS.Resolver

  @option_key "option-icons"

  @omitted_source_keys [
    "icon-size-2xl",
    "icon-padding-2xl",
    "icon-shadow",
    "icon-block-offset",
    "icon-inline-offset",
    "icon-default-style",
    "icon-data-attribute"
  ]

  @gated_source_keys [
    @option_key,
    "icon-default-scheme",
    "icon-size-xs",
    "icon-size-s",
    "icon-size-m",
    "icon-size-l",
    "icon-size-xl",
    "icon-size-2xl",
    "icon-padding",
    "icon-padding-xs",
    "icon-padding-s",
    "icon-padding-m",
    "icon-padding-l",
    "icon-padding-xl",
    "icon-padding-2xl",
    "icon-radius",
    "icon-background",
    "icon-background-hover",
    "icon-border-color",
    "icon-border-color-hover",
    "icon-border-width",
    "icon-border-style",
    "icon-color",
    "icon-color-hover",
    "icon-list-icon-size",
    "icon-list-gap",
    "icon-block-offset",
    "icon-inline-offset",
    "icon-default-style",
    "icon-data-attribute"
  ]

  @reference_targets %{
    "--radius" => {"radius.base", "--radius"},
    "--neutral-ultra-light" => {"color.neutral.ultra_light", "--neutral-ultra-light"},
    "--neutral-light" => {"color.neutral.light", "--neutral-light"},
    "--primary" => {"color.primary", "--primary"},
    "--icon-padding" => {"icon.padding.default", "--icon-padding"}
  }

  @output_variables %{
    "icon.scheme" => "--icon-scheme",
    "icon.size.default" => "--icon-size",
    "icon.padding.default" => "--icon-padding",
    "icon.radius" => "--icon-radius",
    "icon.background" => "--icon-background",
    "icon.background_hover" => "--icon-background-hover",
    "icon.border.color" => "--icon-border-color",
    "icon.border.color_hover" => "--icon-border-color-hover",
    "icon.border.width" => "--icon-border-width",
    "icon.border.style" => "--icon-border-style",
    "icon.color" => "--icon-color",
    "icon.color_hover" => "--icon-color-hover",
    "icon.list.icon_size" => "--icon-list-icon-size",
    "icon.list.gap" => "--icon-list-gap",
    "icon.size.xs" => "--icon-size-xs",
    "icon.size.s" => "--icon-size-s",
    "icon.size.m" => "--icon-size-m",
    "icon.size.l" => "--icon-size-l",
    "icon.size.xl" => "--icon-size-xl",
    "icon.padding.xs" => "--icon-padding-xs",
    "icon.padding.s" => "--icon-padding-s",
    "icon.padding.m" => "--icon-padding-m",
    "icon.padding.l" => "--icon-padding-l",
    "icon.padding.xl" => "--icon-padding-xl"
  }

  @size_variants ~w(xs s m l xl)
  @padding_variants ~w(xs s m l xl)

  @spec enabled?(map()) :: boolean()
  def enabled?(settings) when is_map(settings) do
    Map.get(settings, @option_key) == "on"
  end

  def enabled?(_settings), do: false

  @spec source_keys() :: [String.t()]
  def source_keys, do: @gated_source_keys

  @spec omitted_source_keys() :: [String.t()]
  def omitted_source_keys, do: @omitted_source_keys

  @spec entries(map()) :: [map()]
  def entries(settings) when is_map(settings) do
    if enabled?(settings) do
      base_entries() ++ size_entries() ++ padding_entries()
    else
      []
    end
  end

  def entries(_settings), do: []

  @spec output_variable(String.t()) :: String.t() | nil
  def output_variable(path), do: Map.get(@output_variables, path)

  @spec resolve_css_value(term(), String.t()) :: map()
  def resolve_css_value(raw_value, source_key) when is_binary(source_key) do
    case reference_target(raw_value) do
      {:ok, _variable, target_path, expected_variable} ->
        Resolver.reference(raw_value, target_path, source_key, expected_variable)

      :literal ->
        Resolver.literal(raw_value, :css)

      {:unresolved, _variable} ->
        Resolver.unresolved(
          raw_value,
          source_key,
          "source variable has no proven semantic target"
        )

      :error ->
        Resolver.unresolved(raw_value, source_key, "value is not a supported icon CSS expression")
    end
  end

  @spec resolve_dimension(term(), String.t()) :: map()
  def resolve_dimension(raw_value, source_key) when is_binary(source_key) do
    case parse_dimension(raw_value) do
      {:ok, result} ->
        Resolver.literal(result, :css)

      :error ->
        Resolver.unresolved(raw_value, source_key, "expected a supported px or em dimension")
    end
  end

  @spec resolve_icon_size_default(map()) :: map()
  def resolve_icon_size_default(settings) when is_map(settings) do
    case Map.get(settings, "icon-size") do
      value when is_binary(value) and value != "" ->
        metadata = %{
          "source_keys" => ["icon-size"],
          "output_alias" => %{
            "source_key" => "icon-size",
            "authority_id" => "automatic-css-4.0.1:setting:icon-size:css-variable-reference"
          }
        }

        result = resolve_dimension(value, "icon-size")
        Map.update(result, :metadata, metadata, &Map.merge(&1, metadata))

      _ ->
        case Map.get(settings, "icon-size-m") do
          value when is_binary(value) and value != "" ->
            metadata = %{
              "effective_raw_value" => value,
              "source_keys" => ["icon-size-m"],
              "fallback_from" => "icon-size-m",
              "fallback_reason" =>
                "Automatic.css 4.0.1 SCSS sets $icon-size from $icon-size-m when icon-size is unset",
              "output_alias" => %{
                "source_key" => "icon-size-m",
                "authority_id" =>
                  "automatic-css-4.0.1:icon-default-fallback:icon-size-m:icon-size"
              }
            }

            result = resolve_dimension(value, "icon-size-m")
            Map.update(result, :metadata, metadata, &Map.merge(&1, metadata))

          _ ->
            Resolver.unresolved(nil, "icon-size", "icon default size source is missing")
        end
    end
  end

  defp base_entries do
    [
      literal("icon.scheme", "icon-default-scheme"),
      %{
        path: "icon.size.default",
        category: :icon,
        strategy: :icon_size_default,
        source_keys: ["icon-size", "icon-size-m"]
      },
      literal("icon.padding.default", "icon-padding"),
      css_reference("icon.radius", "icon-radius", "--radius", "radius.base"),
      css_reference(
        "icon.background",
        "icon-background",
        "--neutral-ultra-light",
        "color.neutral.ultra_light"
      ),
      css_reference(
        "icon.background_hover",
        "icon-background-hover",
        "--neutral-light",
        "color.neutral.light"
      ),
      css_value("icon.border.color", "icon-border-color"),
      css_value("icon.border.color_hover", "icon-border-color-hover"),
      css_value("icon.border.width", "icon-border-width"),
      css_value("icon.border.style", "icon-border-style"),
      css_value("icon.color", "icon-color"),
      css_reference("icon.color_hover", "icon-color-hover", "--primary", "color.primary"),
      literal("icon.list.icon_size", "icon-list-icon-size"),
      literal("icon.list.gap", "icon-list-gap")
    ]
  end

  defp size_entries do
    Enum.map(@size_variants, fn variant ->
      %{
        path: "icon.size.#{variant}",
        category: :icon,
        strategy: :icon_dimension,
        source_keys: ["icon-size-#{variant}"]
      }
    end)
  end

  defp padding_entries do
    Enum.map(@padding_variants, fn variant ->
      %{
        path: "icon.padding.#{variant}",
        category: :icon,
        strategy: :icon_css_value,
        source_keys: ["icon-padding-#{variant}"],
        reference_path: "icon.padding.default",
        expected_variable: "--icon-padding"
      }
    end)
  end

  defp literal(path, source_key) do
    %{
      path: path,
      category: :icon,
      strategy: :literal,
      source_keys: [source_key],
      kind: :css
    }
  end

  defp css_value(path, source_key) do
    %{
      path: path,
      category: :icon,
      strategy: :icon_css_value,
      source_keys: [source_key]
    }
  end

  defp css_reference(path, source_key, expected_variable, reference_path) do
    %{
      path: path,
      category: :icon,
      strategy: :icon_css_value,
      source_keys: [source_key],
      reference_path: reference_path,
      expected_variable: expected_variable
    }
  end

  defp reference_target(raw_value) when is_binary(raw_value) do
    case Resolver.css_reference_variable(raw_value) do
      {:ok, variable} ->
        case Map.fetch(@reference_targets, variable) do
          {:ok, {target_path, expected_variable}} ->
            {:ok, variable, target_path, expected_variable}

          :error ->
            {:unresolved, variable}
        end

      :error ->
        if raw_value != "" do
          :literal
        else
          :error
        end
    end
  end

  defp reference_target(_raw_value), do: :error

  defp parse_dimension(value) when is_binary(value) do
    case Regex.run(~r/^(\d+(?:\.\d+)?)(px|em|rem|%)$/, value) do
      [_, _number, _unit] -> {:ok, value}
      _ -> :error
    end
  end

  defp parse_dimension(_value), do: :error
end
