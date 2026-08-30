defmodule LiveFrames.Adapters.AutomaticCSS.Normalizer do
  @moduledoc """
  The authoritative initial mapping from Automatic.css setting keys to
  source-independent LiveFrames semantic token paths.
  """

  alias LiveFrames.Adapters.AutomaticCSS.Resolver
  alias LiveFrames.Tokens.Diagnostic
  alias LiveFrames.Tokens.Token

  @adapter_version "1.0.0"

  @spec mapping() :: [map()]
  def mapping do
    primary_colors =
      [
        direct("color.primary", :color, "color-primary", :color)
      ] ++
        Enum.map(
          ["hover", "light", "semi-light", "dark", "semi-dark", "ultra-light", "ultra-dark"],
          &hsl_entry("color.primary.#{underscore(&1)}", "primary", &1)
        )

    neutral_colors =
      [
        direct("color.neutral", :color, "color-neutral", :color)
      ] ++
        Enum.map(
          ["light", "semi-light", "dark", "semi-dark", "ultra-light", "ultra-dark"],
          &hsl_entry("color.neutral.#{underscore(&1)}", "neutral", &1)
        )

    color_entries =
      primary_colors ++
        neutral_colors ++
        [
          direct("color.base", :color, "color-base", :color),
          hsl_entry("color.base.ultra_light", "base", "ultra-light"),
          reference(
            "color.background.light",
            :color,
            "bg-light",
            "color.base.ultra_light",
            "--base-ultra-light"
          ),
          reference(
            "color.background.dark",
            :color,
            "bg-dark",
            "color.neutral.dark",
            "--neutral-dark"
          ),
          reference(
            "color.background.ultra_light",
            :color,
            "bg-ultra-light",
            "color.neutral.ultra_light",
            "--neutral-ultra-light"
          ),
          reference(
            "color.background.ultra_dark",
            :color,
            "bg-ultra-dark",
            "color.neutral.ultra_dark",
            "--neutral-ultra-dark"
          ),
          foundation("color.black", :color, "--black", "#000", "#fff"),
          foundation("color.white", :color, "--white", "#fff", "#000"),
          reference("color.text.dark", :color, "text-dark", "color.black", "--black"),
          reference("color.text.light", :color, "text-light", "color.white", "--white"),
          reference(
            "color.background.ultra_dark.text",
            :color,
            "bg-ultra-dark-text",
            "color.text.light",
            "--text-light"
          ),
          reference(
            "color.background.ultra_dark.heading",
            :color,
            "bg-ultra-dark-heading",
            "color.text.light",
            "--text-light"
          )
        ]

    base_spacing_inputs = [
      {"mobile_base", "base-space-min"},
      {"desktop_base", "base-space"},
      {"mobile_scale", "mob-space-scale"},
      {"desktop_scale", "space-scale"},
      {"viewport_min", "vp-min"},
      {"viewport_max", "vp-max"}
    ]

    spacing_entries = [
      px("spacing.base.min", :spacing, "base-space-min"),
      px("spacing.base.max", :spacing, "base-space"),
      derived(
        "spacing.scale.medium",
        :spacing,
        "space-m",
        base_spacing_inputs,
        ["spacing.base.min", "spacing.base.max", "layout.viewport.min", "layout.viewport.max"],
        "spacing"
      ),
      derived(
        "spacing.scale.xl",
        :spacing,
        "space-xl",
        base_spacing_inputs,
        ["spacing.base.min", "spacing.base.max", "layout.viewport.min", "layout.viewport.max"],
        "spacing"
      ),
      reference(
        "spacing.content_gap",
        :spacing,
        "contextual-content-gap",
        "spacing.scale.medium",
        "--space-m"
      ),
      reference(
        "spacing.grid_gap",
        :spacing,
        "contextual-grid-gap",
        "spacing.scale.medium",
        "--space-m"
      ),
      reference(
        "spacing.container_gap",
        :spacing,
        "contextual-container-gap",
        "spacing.scale.xl",
        "--space-xl"
      ),
      derived(
        "spacing.section",
        :spacing,
        "section-space-m",
        [
          {"mobile_base", "base-space-min"},
          {"desktop_base", "base-space"},
          {"mobile_scale", "mob-space-scale"},
          {"desktop_scale", "space-scale"},
          {"mobile_adjustment", "mob-space-adjust-section"},
          {"desktop_adjustment", "space-adjust-section"},
          {"viewport_min", "vp-min"},
          {"viewport_max", "vp-max"}
        ],
        ["spacing.base.min", "spacing.base.max", "layout.viewport.min", "layout.viewport.max"],
        "section-spacing"
      ),
      reference(
        "spacing.section.padding_block",
        :spacing,
        "section-padding-block",
        "spacing.section",
        "--section-space-m"
      ),
      px("spacing.gutter.min", :spacing, "gutter-min"),
      px("spacing.gutter.max", :spacing, "gutter-max"),
      direct("radius.base", :radius, "base-radius", :css)
    ]

    typography_entries = [
      responsive(
        "typography.body.base_size",
        :typography,
        ["base-text-mob", "base-text-desk"],
        "px"
      ),
      responsive("typography.body.scale", :typography, ["mob-text-scale", "text-scale"], nil),
      derived(
        "typography.body.scale.medium",
        :typography,
        "text-m",
        [
          {"mobile_base", "base-text-mob"},
          {"desktop_base", "base-text-desk"},
          {"mobile_scale", "mob-text-scale"},
          {"desktop_scale", "text-scale"},
          {"viewport_min", "vp-min"},
          {"viewport_max", "vp-max"}
        ],
        ["typography.body.base_size", "layout.viewport.min", "layout.viewport.max"],
        "text"
      ),
      direct("typography.body.line_height", :typography, "base-text-lh", :css),
      responsive(
        "typography.heading.base_size",
        :typography,
        ["base-heading-mob", "base-heading-desk"],
        "px"
      ),
      responsive(
        "typography.heading.scale",
        :typography,
        ["mob-heading-scale", "heading-scale"],
        nil
      ),
      derived(
        "typography.heading.scale.h1",
        :typography,
        "h1",
        [
          {"mobile_base", "base-heading-mob"},
          {"desktop_base", "base-heading-desk"},
          {"mobile_scale", "mob-heading-scale"},
          {"desktop_scale", "heading-scale"},
          {"viewport_min", "vp-min"},
          {"viewport_max", "vp-max"}
        ],
        ["typography.heading.base_size", "layout.viewport.min", "layout.viewport.max"],
        "headings"
      ),
      direct("typography.heading.line_height", :typography, "base-heading-lh", :css)
    ]

    button_entries = [
      reference(
        "button.primary.background",
        :button,
        "btn-primary-bg",
        "color.primary",
        "--primary"
      ),
      reference(
        "button.primary.background_hover",
        :button,
        "btn-primary-hover",
        "color.primary.hover",
        "--primary-hover"
      ),
      reference(
        "button.primary.text",
        :button,
        "btn-primary-text",
        "color.primary.ultra_dark",
        "--primary-ultra-dark"
      ),
      reference(
        "button.primary.border",
        :button,
        "btn-primary-border-color",
        "button.primary.background",
        "--btn-background"
      ),
      reference(
        "button.primary.focus",
        :button,
        "btn-primary-focus-color",
        "color.primary.light",
        "--primary-light"
      ),
      reference(
        "button.primary.radius",
        :button,
        "btn-border-radius",
        "radius.base",
        "--radius"
      ),
      direct("button.primary.padding_inline", :button, "btn-padding-inline", :css),
      direct("button.primary.padding_block", :button, "btn-padding-block", :css),
      px("button.primary.min_width", :button, "btn-min-width"),
      reference(
        "button.primary.font_size",
        :button,
        "btn-font-size",
        "typography.body.scale.medium",
        "--text-m"
      ),
      direct("button.primary.font_weight", :button, "btn-font-weight", :string),
      direct("button.primary.line_height", :button, "btn-line-height", :any),
      direct("button.primary.border_width", :button, "btn-border-width", :css),
      direct("button.primary.border_style", :button, "btn-border-style", :string),
      direct(
        "button.primary.outline.background",
        :button,
        "btn-primary-outline-background",
        :css
      ),
      reference(
        "button.primary.outline.background_hover",
        :button,
        "btn-primary-outline-background-hover",
        "color.primary.hover",
        "--primary-hover"
      ),
      reference(
        "button.primary.outline.border",
        :button,
        "btn-primary-outline-border-color",
        "color.primary",
        "--primary"
      ),
      reference(
        "button.primary.outline.border_hover",
        :button,
        "btn-primary-outline-border-hover",
        "button.primary.background_hover",
        "--btn-background-hover"
      ),
      reference(
        "button.primary.outline.focus",
        :button,
        "btn-primary-outline-focus-color",
        "color.primary.semi_light",
        "--primary-semi-light"
      ),
      reference(
        "button.primary.outline.text",
        :button,
        "primary-outline-btn-text",
        "color.primary",
        "--primary"
      ),
      reference(
        "button.primary.outline.text_hover",
        :button,
        "primary-outline-hover-text",
        "color.primary.ultra_light",
        "--primary-ultra-light"
      )
    ]

    layout_entries = [
      px("layout.viewport.min", :layout, "vp-min"),
      px("layout.viewport.max", :layout, "vp-max"),
      px("layout.breakpoint.auto_grid", :layout, "auto-staggered-grid-breakpoint")
    ]

    (color_entries ++ spacing_entries ++ typography_entries ++ button_entries ++ layout_entries)
    |> Enum.sort_by(& &1.path)
  end

  @spec source_keys() :: [String.t()]
  def source_keys do
    mapping()
    |> Enum.flat_map(& &1.source_keys)
    |> Enum.uniq()
    |> Enum.sort()
  end

  @spec normalize(map(), map(), keyword()) :: {map(), [Diagnostic.t()]}
  def normalize(settings, source_metadata, _opts)
      when is_map(settings) and is_map(source_metadata) do
    {tokens, diagnostics, consumed} =
      Enum.reduce(mapping(), {%{}, [], MapSet.new()}, fn entry, {tokens, diagnostics, consumed} ->
        consumed = Enum.reduce(entry.source_keys, consumed, &MapSet.put(&2, &1))

        if Map.has_key?(tokens, entry.path) do
          diagnostic =
            Diagnostic.new(
              code: "acss.mapping.conflict",
              severity: :error,
              category: :mapping,
              message: "multiple Automatic.css mappings target the same canonical path",
              path: entry.path,
              metadata: %{"source_keys" => entry.source_keys}
            )

          {tokens, [diagnostic | diagnostics], consumed}
        else
          raw_value = source_value(settings, entry.source_keys)
          result = resolve_entry(entry, settings)
          token = build_token(entry, result, raw_value, source_metadata)
          diagnostics = diagnostics ++ diagnostics_for(entry, result, raw_value)
          {Map.put(tokens, entry.path, token), diagnostics, consumed}
        end
      end)

    {tokens, diagnostics} = resolve_reference_values(tokens, diagnostics)
    diagnostics = add_unknown_settings(settings, consumed, diagnostics)
    {tokens, sort_diagnostics(diagnostics)}
  end

  defp resolve_entry(%{strategy: :literal, source_keys: [source_key], kind: kind}, settings) do
    raw_value = Map.get(settings, source_key)

    if present?(raw_value) do
      Resolver.literal(raw_value, kind)
    else
      Resolver.unresolved(raw_value, source_key, "source setting is missing or empty")
    end
  end

  defp resolve_entry(%{strategy: :px, source_keys: [source_key]}, settings) do
    raw_value = Map.get(settings, source_key)

    if present?(raw_value) do
      Resolver.px(raw_value, source_key)
    else
      Resolver.unresolved(raw_value, source_key, "source setting is missing or empty")
    end
  end

  defp resolve_entry(%{strategy: :hsl, source_keys: source_keys}, settings),
    do: Resolver.hsl(settings, source_keys)

  defp resolve_entry(
         %{
           strategy: :foundation,
           source_keys: source_keys,
           variable: variable,
           light_value: light_value,
           dark_value: dark_value
         },
         settings
       ),
       do: Resolver.foundation(settings, variable, light_value, dark_value, source_keys)

  defp resolve_entry(
         %{
           strategy: :reference,
           source_keys: [source_key],
           reference_path: reference_path,
           expected_variable: expected_variable
         },
         settings
       ) do
    raw_value = Map.get(settings, source_key)

    if present?(raw_value) do
      Resolver.reference(raw_value, reference_path, source_key, expected_variable)
    else
      Resolver.unresolved(raw_value, source_key, "source setting is missing or empty")
    end
  end

  defp resolve_entry(%{strategy: :responsive, source_keys: source_keys, unit: unit}, settings),
    do: Resolver.responsive(settings, source_keys, unit)

  defp resolve_entry(
         %{strategy: :derived, source_keys: source_keys, inputs: inputs} = entry,
         settings
       ) do
    input_values =
      Map.new(inputs, fn {name, source_key} -> {name, Map.get(settings, source_key)} end)

    raw_value = source_value(settings, source_keys)

    if Enum.all?(Map.values(input_values), &number?/1) do
      Resolver.derived(
        entry.recipe,
        entry.variable,
        Map.put(input_values, "calculation_group", entry.calculation_group),
        entry.references,
        source_keys
      )
    else
      Resolver.unresolved(
        raw_value,
        List.first(source_keys),
        "derived source inputs are incomplete or invalid"
      )
    end
  end

  defp build_token(entry, result, raw_value, source_metadata) do
    provenance = %{
      "source_type" => "automatic_css_settings",
      "source_keys" => entry.source_keys,
      "raw_value" => raw_value,
      "adapter" => "automatic_css",
      "adapter_version" => @adapter_version,
      "transformation" => result.transformation,
      "source_version" => Map.get(source_metadata, "source_version"),
      "export_version" => Map.get(source_metadata, "export_version")
    }

    provenance = Map.merge(provenance, Map.get(entry, :provenance, %{}))

    metadata =
      entry
      |> Map.get(:metadata, %{})
      |> Map.merge(result.metadata)

    %Token{
      path: entry.path,
      category: entry.category,
      value: result.value,
      resolved_value: result.resolved_value,
      source_expression: result.source_expression,
      resolution_status: result.resolution_status,
      references: result.references,
      provenance: provenance,
      metadata: metadata
    }
  end

  defp diagnostics_for(entry, result, raw_value) do
    if result.resolution_status == :unresolved do
      reason = get_in(result, [:metadata, "reason"]) || "source value could not be resolved"

      {code, severity} =
        if present_source_value?(raw_value) do
          {"acss.value.unresolved", :warning}
        else
          {"acss.setting.invalid", :warning}
        end

      [
        Diagnostic.new(
          code: code,
          severity: severity,
          category: :value,
          message: reason,
          path: entry.path,
          source_key: List.first(entry.source_keys),
          metadata: %{"source_keys" => entry.source_keys}
        )
      ]
    else
      []
    end
  end

  defp resolve_reference_values(tokens, diagnostics) do
    tokens
    |> Map.keys()
    |> Enum.sort()
    |> Enum.reduce({tokens, diagnostics}, fn path, {tokens, diagnostics} ->
      token = Map.fetch!(tokens, path)

      if reference_token?(token) do
        target_path = token.value["path"]

        case effective_value(target_path, tokens, [path]) do
          {:resolved, resolved_value, _reason} ->
            {Map.put(tokens, path, %{
               token
               | resolved_value: resolved_value,
                 resolution_status: :resolved
             }), diagnostics}

          {:unresolved, _resolved_value, reason} ->
            token = %{token | resolved_value: nil, resolution_status: :unresolved}

            diagnostic =
              Diagnostic.new(
                code: "acss.value.unresolved",
                severity: :warning,
                category: :reference,
                message: reason || "semantic reference could not be resolved",
                path: path,
                source_key: List.first(token.provenance["source_keys"]),
                metadata: %{"reference" => target_path}
              )

            {Map.put(tokens, path, token), [diagnostic | diagnostics]}
        end
      else
        {tokens, diagnostics}
      end
    end)
  end

  defp effective_value(path, tokens, stack) do
    cond do
      not is_binary(path) or not Map.has_key?(tokens, path) ->
        {:unresolved, nil, "semantic reference target is missing"}

      path in stack ->
        {:unresolved, nil, "semantic reference contains a cycle"}

      true ->
        token = Map.fetch!(tokens, path)

        if reference_token?(token) do
          effective_value(token.value["path"], tokens, [path | stack])
        else
          {token.resolution_status, token.resolved_value, nil}
        end
    end
  end

  defp add_unknown_settings(settings, consumed, diagnostics) do
    unknown_keys =
      settings
      |> Map.keys()
      |> Enum.reject(&MapSet.member?(consumed, &1))
      |> Enum.sort()

    case unknown_keys do
      [] ->
        diagnostics

      _ ->
        diagnostic =
          Diagnostic.new(
            code: "acss.setting.unknown",
            severity: :info,
            category: :source,
            message: "unrelated Automatic.css settings were ignored",
            metadata: %{
              "count" => length(unknown_keys),
              "sample_keys" => Enum.take(unknown_keys, 10)
            }
          )

        [diagnostic | diagnostics]
    end
  end

  defp sort_diagnostics(diagnostics) do
    Enum.sort_by(diagnostics, fn diagnostic ->
      {diagnostic.code || "", diagnostic.path || "", diagnostic.source_key || "",
       diagnostic.message || ""}
    end)
  end

  defp source_value(settings, [source_key]), do: Map.get(settings, source_key)

  defp source_value(settings, source_keys) do
    Map.new(source_keys, &{&1, Map.get(settings, &1)})
  end

  defp present?(value), do: not is_nil(value) and value != ""
  defp present_source_value?(value), do: present?(value)
  defp number?(value), do: is_integer(value) or is_float(value)

  defp reference_token?(%Token{value: %{"type" => "reference"}}), do: true
  defp reference_token?(_token), do: false

  defp direct(path, category, source_key, kind),
    do: %{
      path: path,
      category: category,
      strategy: :literal,
      source_keys: [source_key],
      kind: kind
    }

  defp px(path, category, source_key),
    do: %{path: path, category: category, strategy: :px, source_keys: [source_key]}

  defp hsl_entry(path, source_prefix, variant) do
    source_prefix = "#{source_prefix}-#{variant}"

    %{
      path: path,
      category: :color,
      strategy: :hsl,
      source_keys: ["#{source_prefix}-h", "#{source_prefix}-s", "#{source_prefix}-l"]
    }
  end

  defp reference(path, category, source_key, reference_path, expected_variable),
    do: %{
      path: path,
      category: category,
      strategy: :reference,
      source_keys: [source_key],
      reference_path: reference_path,
      expected_variable: expected_variable
    }

  defp foundation(path, category, variable, light_value, dark_value),
    do: %{
      path: path,
      category: category,
      strategy: :foundation,
      source_keys: ["option-bw-color-variables", "auto-color-scheme"],
      variable: variable,
      light_value: light_value,
      dark_value: dark_value,
      provenance: %{
        "source_type" => "automatic_css_reference_contract",
        "source_variable" => variable,
        "source_contract_version" => "4.0.1",
        "source_reference" =>
          "Automatic.css 4.0.1 palette/main/_bw.scss and color-scheme/_auto-scheme.scss"
      }
    }

  defp responsive(path, category, source_keys, unit),
    do: %{
      path: path,
      category: category,
      strategy: :responsive,
      source_keys: source_keys,
      unit: unit
    }

  defp derived(path, category, variable, inputs, references, calculation_group),
    do: %{
      path: path,
      category: category,
      strategy: :derived,
      source_keys: Enum.map(inputs, &elem(&1, 1)),
      inputs: inputs,
      references: references,
      recipe: "acss.clamp",
      variable: variable,
      calculation_group: calculation_group,
      metadata: %{"calculation_group" => calculation_group}
    }

  defp underscore(value), do: String.replace(value, "-", "_")
end
