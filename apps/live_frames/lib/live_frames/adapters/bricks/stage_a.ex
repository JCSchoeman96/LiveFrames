defmodule LiveFrames.Adapters.Bricks.StageA do
  @moduledoc """
  Pure-to-filesystem orchestration for deterministic Bricks Stage A output.

  This module stops at source extraction. It does not create Design IR,
  LiveFrames components, HEEx, or Tailwind output.
  """

  alias LiveFrames.Adapters.Bricks
  alias LiveFrames.Adapters.Bricks.ClassResolver
  alias LiveFrames.Adapters.Bricks.DependencyExtractor
  alias LiveFrames.Adapters.Bricks.Diagnostic
  alias LiveFrames.Adapters.Bricks.Document
  alias LiveFrames.Adapters.Bricks.Loader
  alias LiveFrames.Adapters.Bricks.Result
  alias LiveFrames.Adapters.Bricks.Serializer
  alias LiveFrames.Adapters.Bricks.StageA.CSSRenderer
  alias LiveFrames.Adapters.Bricks.StageA.HTMLRenderer
  alias LiveFrames.Adapters.Bricks.StageA.Report

  @adapter_version "1.0.0"
  @stage_a_schema_version "1.0.0"
  @artifact_names ["index.html", "styles.css", "report.json"]
  @default_component_id "sqhmmc"

  @spec adapter_version() :: String.t()
  def adapter_version, do: @adapter_version

  @spec stage_a_schema_version() :: String.t()
  def stage_a_schema_version, do: @stage_a_schema_version

  @spec artifact_names() :: [String.t()]
  def artifact_names, do: @artifact_names

  @spec generate_from_file(term(), keyword()) :: {:ok, Result.t()} | {:error, list()}
  def generate_from_file(path, opts \\ []) do
    case Loader.from_file(path, opts) do
      {:ok, document, diagnostics} -> generate_document(document, diagnostics, opts)
      {:error, diagnostics} -> {:error, diagnostics}
    end
    |> maybe_write(opts)
  end

  @spec generate(term(), keyword()) :: {:ok, Result.t()} | {:error, list()}
  def generate(source, opts \\ [])

  def generate(%Document{} = document, opts),
    do: generate_document(document, [], opts) |> maybe_write(opts)

  def generate(source, opts) when is_binary(source) do
    case Bricks.from_json(source, opts) do
      {:ok, document, diagnostics} -> generate_document(document, diagnostics, opts)
      {:error, diagnostics} -> {:error, diagnostics}
    end
    |> maybe_write(opts)
  end

  def generate(source, opts) when is_map(source) do
    case Bricks.recognize(source, opts) do
      {:ok, document, diagnostics} -> generate_document(document, diagnostics, opts)
      {:error, diagnostics} -> {:error, diagnostics}
    end
    |> maybe_write(opts)
  end

  def generate(_source, _opts),
    do:
      {:error,
       [
         Diagnostic.new(
           code: "bricks.source.invalid",
           message: "Stage A source must be a Bricks document, map, or JSON text"
         )
       ]}

  @spec write_artifacts(Result.t(), term()) :: {:ok, Result.t()} | {:error, list()}
  def write_artifacts(%Result{} = result, output_dir) when is_binary(output_dir) do
    File.mkdir_p!(output_dir)

    Enum.each(@artifact_names, fn name ->
      File.write!(Path.join(output_dir, name), Map.fetch!(result.artifacts, name))
    end)

    {:ok, %{result | artifact_paths: artifact_paths(output_dir)}}
  rescue
    exception ->
      {:error,
       [
         Diagnostic.new(
           code: "bricks.artifact.write_failed",
           severity: :fatal,
           message: "Stage A artifacts could not be written",
           metadata: %{"reason" => Exception.message(exception)}
         )
       ]}
  end

  @spec verify_drift(keyword()) :: :ok | {:error, list()}
  def verify_drift(opts) when is_list(opts) do
    expected_dir = Keyword.get(opts, :expected_dir)
    temporary_dir = Keyword.get(opts, :temporary_dir)
    source_path = Keyword.get(opts, :source_path)

    if Enum.all?([expected_dir, temporary_dir, source_path], &is_binary/1) do
      generation_result =
        if Keyword.get(opts, :generate, true) do
          generation_opts =
            opts
            |> Keyword.delete(:expected_dir)
            |> Keyword.delete(:temporary_dir)
            |> Keyword.put(:output_dir, temporary_dir)

          generate_from_file(source_path, generation_opts)
        else
          {:ok, nil}
        end

      case generation_result do
        {:ok, _result} -> compare_artifacts(expected_dir, temporary_dir)
        {:error, diagnostics} -> {:error, diagnostics}
      end
    else
      {:error,
       [
         Diagnostic.new(
           code: "bricks.artifact.invalid_options",
           severity: :error,
           message: "Drift verification requires expected_dir, temporary_dir, and source_path"
         )
       ]}
    end
  end

  defp generate_document(document, loader_diagnostics, opts) do
    result =
      Result.new(document: document, diagnostics: loader_diagnostics)
      |> Result.advance(:recognized)
      |> Result.advance(:validated)

    with {:ok, proxy, component, resolve_diagnostics} <-
           Bricks.resolve(document,
             component_id: Keyword.get(opts, :component_id, @default_component_id)
           ),
         result <-
           %{result | proxy: proxy, component: component}
           |> Result.add_diagnostics(resolve_diagnostics)
           |> Result.advance(:resolved),
         {:ok, tree, tree_diagnostics} <- Bricks.build_tree(component),
         :ok <- expected_root_count(tree, opts),
         result <-
           %{result | tree: tree}
           |> Result.add_diagnostics(tree_diagnostics)
           |> Result.advance(:tree_built),
         {:ok, resolved, class_diagnostics} <- ClassResolver.resolve(tree, document),
         dependencies <-
           DependencyExtractor.extract(resolved, document,
             token_set: Keyword.get(opts, :token_set)
           ),
         unsupported_diagnostics <- unsupported_element_diagnostics(tree),
         result <-
           %{result | dependencies: Map.put(dependencies, :resolved, resolved)}
           |> Result.add_diagnostics(
             class_diagnostics ++ dependencies.diagnostics ++ unsupported_diagnostics
           )
           |> Result.advance(:dependencies_extracted),
         html <-
           HTMLRenderer.render(resolved,
             title: Keyword.get(opts, :title, "Bricks Stage A"),
             stylesheet: Keyword.get(opts, :stylesheet, "styles.css")
           ),
         css <- CSSRenderer.render(resolved),
         result <-
           %{result | artifacts: %{"index.html" => html, "styles.css" => css}}
           |> Result.advance(:rendered),
         report <- Report.build(result, dependencies, opts),
         report_bytes <- Serializer.encode!(report) <> "\n",
         result <-
           %{
             result
             | report: report,
               artifacts: Map.put(result.artifacts, "report.json", report_bytes)
           }
           |> Result.advance(:verified)
           |> Result.advance(:completed) do
      {:ok, result}
    else
      {:error, diagnostics} ->
        {:error, diagnostics}

      :error ->
        {:error,
         [
           Diagnostic.new(
             code: "bricks.stage_a.failed",
             severity: :error,
             message: "Stage A extraction failed"
           )
         ]}
    end
  rescue
    exception ->
      {:error,
       [
         Diagnostic.new(
           code: "bricks.stage_a.failed",
           severity: :fatal,
           message: "Stage A extraction failed",
           metadata: %{"reason" => Exception.message(exception)}
         )
       ]}
  end

  defp expected_root_count(tree, opts) do
    expected = Keyword.get(opts, :expected_root_count, 1)

    if length(tree.root_ids) == expected do
      :ok
    else
      {:error,
       [
         Diagnostic.new(
           code: "bricks.tree.root_count",
           severity: :error,
           message: "Stage A expected a different root count",
           raw_value: tree.root_ids,
           metadata: %{"expected" => expected, "actual" => length(tree.root_ids)}
         )
       ]}
    end
  end

  defp unsupported_element_diagnostics(tree) do
    tree.ordered_elements
    |> Enum.filter(&(not supported_element?(&1)))
    |> Enum.map(fn element ->
      Diagnostic.new(
        code: "bricks.element.unsupported",
        severity: :warning,
        source_id: element.id,
        raw_value: element.raw,
        message: "Bricks element type is preserved but not in the supported Stage A subset"
      )
    end)
  end

  defp supported_element?(element),
    do:
      element.name in ["section", "container", "div", "heading", "text-basic", "button", "image"]

  defp maybe_write({:ok, %Result{} = result}, opts) do
    case Keyword.get(opts, :output_dir) do
      nil -> {:ok, result}
      output_dir -> write_artifacts(result, output_dir)
    end
  end

  defp maybe_write(other, _opts), do: other

  defp compare_artifacts(expected_dir, temporary_dir) do
    expected_entries = directory_entries(expected_dir)
    actual_entries = directory_entries(temporary_dir)

    missing =
      Enum.filter(@artifact_names, fn name ->
        not regular_file?(Path.join(expected_dir, name)) or
          not regular_file?(Path.join(temporary_dir, name))
      end)

    unexpected =
      (Enum.filter(actual_entries, &(&1 not in @artifact_names)) ++
         Enum.filter(expected_entries, &(&1 not in @artifact_names)))
      |> Enum.uniq()

    different =
      @artifact_names
      |> Enum.reject(&(&1 in missing))
      |> Enum.filter(fn name ->
        expected = File.read!(Path.join(expected_dir, name))
        actual = File.read!(Path.join(temporary_dir, name))
        expected != actual
      end)

    diagnostics =
      Enum.map(
        missing,
        &Diagnostic.new(
          code: "bricks.artifact.missing",
          severity: :error,
          source_path: &1,
          message: "Expected Stage A artifact is missing"
        )
      ) ++
        Enum.map(
          different,
          &Diagnostic.new(
            code: "bricks.artifact.different",
            severity: :error,
            source_path: &1,
            message: "Regenerated Stage A artifact differs from the committed artifact"
          )
        ) ++
        Enum.map(
          unexpected,
          &Diagnostic.new(
            code: "bricks.artifact.unexpected",
            severity: :error,
            source_path: &1,
            message: "Unexpected generated artifact is present"
          )
        )

    if diagnostics == [], do: :ok, else: {:error, sort_diagnostics(diagnostics)}
  rescue
    exception ->
      {:error,
       [
         Diagnostic.new(
           code: "bricks.artifact.invalid",
           severity: :error,
           message: "Stage A artifact directories could not be compared",
           metadata: %{"reason" => Exception.message(exception)}
         )
       ]}
  end

  defp directory_entries(directory) do
    case File.ls(directory) do
      {:ok, entries} -> Enum.sort(entries)
      {:error, _reason} -> []
    end
  end

  defp regular_file?(path), do: match?({:ok, %File.Stat{type: :regular}}, File.stat(path))

  defp artifact_paths(output_dir),
    do: Map.new(@artifact_names, &{&1, Path.join(output_dir, &1)})

  defp sort_diagnostics(diagnostics) do
    Enum.sort_by(diagnostics, fn diagnostic ->
      {diagnostic.code || "", diagnostic.source_path || "", diagnostic.source_id || "",
       diagnostic.message || ""}
    end)
  end
end
