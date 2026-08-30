defmodule LiveFrames.Adapters.Bricks.StageA.Report do
  @moduledoc """
  Builds the machine-readable audit report for a Bricks Stage A extraction.
  """

  alias LiveFrames.Adapters.Bricks.Diagnostic
  alias LiveFrames.Adapters.Bricks.Document
  alias LiveFrames.Adapters.Bricks.Result
  alias LiveFrames.Adapters.Bricks.Serializer

  @report_schema_version "1.0.0"
  @stage_a_schema_version "1.0.0"

  @spec report_schema_version() :: String.t()
  def report_schema_version, do: @report_schema_version

  @spec stage_a_schema_version() :: String.t()
  def stage_a_schema_version, do: @stage_a_schema_version

  @spec build(Result.t(), map(), keyword()) :: map()
  def build(%Result{} = result, dependencies, opts \\ []) do
    document = result.document
    component = result.component
    tree = result.tree
    resolved = result.dependencies[:resolved]
    diagnostics = result.diagnostics
    supported_count = Enum.count(tree.ordered_elements, &supported_element?/1)
    unsupported_count = length(tree.ordered_elements) - supported_count
    responsive_entries = dependencies.responsive

    breakpoints =
      responsive_entries
      |> Enum.map(&Map.get(&1, :breakpoint))
      |> Enum.filter(&is_binary/1)
      |> Enum.uniq()
      |> Enum.sort()

    unresolved_breakpoints =
      Enum.count(responsive_entries, &(Map.get(&1, :threshold_status) == :unresolved))

    resolved_breakpoints =
      Enum.count(responsive_entries, &(Map.get(&1, :threshold_status) == :resolved))

    unresolved_variables =
      Enum.filter(
        dependencies.variables,
        &(&1.status in [:source_variable, :unresolved_external])
      )

    token_variables = Enum.filter(dependencies.variables, &(&1.status == :resolved_token))
    acss_classes = dependencies.acss_classes

    report = %{
      report_schema_version: @report_schema_version,
      stage_a_schema_version: @stage_a_schema_version,
      adapter_version: document.adapter_version,
      source: %{
        envelope: document.source,
        url: document.source_url,
        label: document.source_label,
        sha256: document.source_hash
      },
      source_versions: %{
        payload: document.payload_version,
        component: component.version,
        adapter: document.adapter_version,
        stage_a_schema: @stage_a_schema_version
      },
      component: %{
        id: component.id,
        name: component.name,
        category: component.category,
        description: component.description,
        label: result.proxy.label
      },
      lifecycle: result.lifecycle ++ [:verified, :completed],
      roots: %{ids: tree.root_ids, count: length(tree.root_ids)},
      root_ids: tree.root_ids,
      root_count: length(tree.root_ids),
      element_count: length(tree.ordered_elements),
      supported_element_count: supported_count,
      unsupported_element_count: unsupported_count,
      unsupported_elements:
        Enum.filter(tree.ordered_elements, &(not supported_element?(&1)))
        |> Enum.map(&%{source_id: &1.id, type: &1.name, raw: &1.raw}),
      classes: %{
        global_class_count: Document.global_class_count(document),
        source_class_count: length(dependencies.source_classes),
        source_classes: dependencies.source_classes,
        applied: dependencies.class_dependencies,
        acss_classes: acss_classes,
        acss_dependency_count: length(acss_classes)
      },
      global_class_count: Document.global_class_count(document),
      source_class_count: length(dependencies.source_classes),
      source_classes: dependencies.source_classes,
      acss_classes: acss_classes,
      acss_class_dependency_count: length(acss_classes),
      settings: %{
        consumed: dependencies.settings_consumed,
        consumed_count: length(dependencies.settings_consumed),
        unsupported: dependencies.unsupported_settings,
        unsupported_count: length(dependencies.unsupported_settings)
      },
      settings_consumed_count: length(dependencies.settings_consumed),
      unsupported_setting_count: length(dependencies.unsupported_settings),
      responsive: %{
        entries: responsive_entries,
        source_breakpoints: breakpoints,
        resolved_count: resolved_breakpoints,
        unresolved_count: unresolved_breakpoints
      },
      custom_css: dependencies.custom_css,
      variables: %{
        dependencies: dependencies.variables,
        count: length(dependencies.variables),
        token_resolved_count: length(token_variables),
        unresolved_count: length(unresolved_variables),
        unresolved_names: Enum.map(unresolved_variables, & &1.name),
        token_resolved_names: Enum.map(token_variables, & &1.name)
      },
      css_variable_dependency_count: length(dependencies.variables),
      token_resolved_dependency_count: length(token_variables),
      unresolved_css_variable_names: Enum.map(unresolved_variables, & &1.name),
      assets: %{
        items: dependencies.assets,
        count: length(dependencies.assets),
        unresolved_count: Enum.count(dependencies.assets, &(&1.status == :unresolved))
      },
      runtime_dependencies: dependencies.runtime_dependencies,
      diagnostics: %{
        counts: diagnostic_counts(diagnostics),
        items: Enum.map(diagnostics, &diagnostic_to_map/1)
      },
      diagnostic_counts: diagnostic_counts(diagnostics),
      source_trace: %{elements: source_trace(tree, resolved)},
      generation_options: generation_options(opts)
    }

    Serializer.to_map(report)
  end

  defp source_trace(tree, resolved) do
    Enum.map(tree.ordered_elements, fn element ->
      resolved_element =
        if is_map(resolved), do: Map.get(resolved.elements, element.id, %{}), else: %{}

      %{
        source_id: element.id,
        source_index: element.source_index,
        type: element.name,
        parent: element.parent,
        children: element.children,
        label: element.label,
        class_ids: Map.get(resolved_element, :class_ids, []),
        class_names: Map.get(resolved_element, :class_names, []),
        settings_keys: element.settings |> Map.keys() |> Enum.map(&to_string/1) |> Enum.sort(),
        raw: element.raw
      }
    end)
  end

  defp diagnostic_counts(diagnostics) do
    Enum.reduce([:info, :warning, :error, :fatal], %{}, fn severity, counts ->
      Map.put(counts, severity, Enum.count(diagnostics, &(&1.severity == severity)))
    end)
  end

  defp diagnostic_to_map(%Diagnostic{} = diagnostic) do
    %{
      code: diagnostic.code,
      severity: diagnostic.severity,
      category: diagnostic.category,
      message: diagnostic.message,
      source_path: diagnostic.source_path,
      source_id: diagnostic.source_id,
      raw_value: diagnostic.raw_value,
      metadata: diagnostic.metadata
    }
  end

  defp diagnostic_to_map(diagnostic), do: diagnostic

  defp generation_options(opts) do
    %{
      component_id: Keyword.get(opts, :component_id, "sqhmmc"),
      expected_root_count: Keyword.get(opts, :expected_root_count, 1),
      title: Keyword.get(opts, :title, "Bricks Stage A"),
      stylesheet: Keyword.get(opts, :stylesheet, "styles.css")
    }
  end

  defp supported_element?(element),
    do:
      element.name in ["section", "container", "div", "heading", "text-basic", "button", "image"]
end
