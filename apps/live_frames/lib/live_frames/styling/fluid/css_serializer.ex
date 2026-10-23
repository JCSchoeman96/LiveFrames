defmodule LiveFrames.Styling.Fluid.CSSSerializer do
  @moduledoc """
  Realizes resolved FluidValue semantics as deterministic CSS expressions.
  """

  alias LiveFrames.Styling.Fluid.Resolver
  alias LiveFrames.Styling.Fluid.ScaleStep
  alias LiveFrames.Styling.Fluid.Value
  alias LiveFrames.Tokens.Token
  alias LiveFrames.Tokens.TokenSet

  @type resolver_reason ::
          {:token_not_found, String.t()}
          | {:unresolved_dependency, String.t()}
          | {:invalid_root_type, String.t()}
          | {:invalid_dependency_type, String.t(), String.t()}

  @type reason :: resolver_reason() | {:unsupported_realization, String.t()} | :invalid_paths

  @type plan :: %{
          fallback_dependencies: [%{name: String.t(), expression: String.t()}],
          modern_overrides: [%{name: String.t(), expression: String.t()}],
          values: [%{path: String.t(), expression: String.t()}]
        }

  @spec legacy_value(TokenSet.t(), String.t()) :: {:ok, String.t()} | {:error, reason()}
  def legacy_value(%TokenSet{} = token_set, path) when is_binary(path) do
    with {:ok, %{semantic: semantic, domain: domain}} <- resolve_value(token_set, path) do
      {:ok, value_expression(semantic, fallback_progress(domain))}
    end
  end

  def legacy_value(%TokenSet{}, _path), do: {:error, :invalid_paths}

  @spec plan(TokenSet.t(), [String.t()]) :: {:ok, plan()} | {:error, reason()}
  def plan(%TokenSet{} = token_set, paths) when is_list(paths) do
    if Enum.all?(paths, &is_binary/1) do
      compile_plan(token_set, paths)
    else
      {:error, :invalid_paths}
    end
  end

  def plan(%TokenSet{}, _paths), do: {:error, :invalid_paths}

  defp compile_plan(_token_set, []) do
    {:ok, %{fallback_dependencies: [], modern_overrides: [], values: []}}
  end

  defp compile_plan(token_set, paths) do
    initial = %{fallback_dependencies: %{}, modern_overrides: %{}, values: %{}}

    paths
    |> Enum.uniq()
    |> Enum.sort()
    |> Enum.reduce_while({:ok, initial}, fn path, {:ok, acc} ->
      case resolve_plan_root(token_set, path) do
        {:ok, %{semantic: semantic, domain: domain} = resolved_root} ->
          next =
            if Value.type?(semantic) do
              name = domain_variable_name(semantic["domain_ref"])

              acc
              |> add_domain_dependency(name, domain)
              |> Map.update!(:values, fn values ->
                Map.put(values, path, %{
                  path: path,
                  expression: value_expression(semantic, "var(#{name})")
                })
              end)
            else
              %{scale: scale} = resolved_root
              domain_name = domain_variable_name(scale["domain_ref"])
              {base_name, ratio_name} = scale_variable_names(semantic["scale_ref"])

              acc
              |> add_domain_dependency(domain_name, domain)
              |> add_scale_dependencies(semantic["scale_ref"], scale, domain_name)
              |> Map.update!(:values, fn values ->
                Map.put(values, path, %{
                  path: path,
                  expression: scale_step_expression(base_name, ratio_name, semantic["power"])
                })
              end)
            end

          {:cont, {:ok, next}}

        {:error, reason} ->
          {:halt, {:error, reason}}
      end
    end)
    |> case do
      {:ok, acc} -> {:ok, sort_plan(acc)}
      {:error, reason} -> {:error, reason}
    end
  end

  defp resolve_value(token_set, path) do
    case Resolver.resolve(token_set, path) do
      {:ok, %{semantic: semantic, domain: domain}} ->
        if Value.type?(semantic) do
          {:ok, %{semantic: semantic, domain: domain}}
        else
          {:error, {:unsupported_realization, path}}
        end

      {:ok, _resolved_root} ->
        {:error, {:unsupported_realization, path}}

      {:error, {:invalid_root_type, ^path} = reason} ->
        invalid_root_result(token_set, path, reason)

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp resolve_plan_root(token_set, path) do
    case Resolver.resolve(token_set, path) do
      {:ok, %{semantic: semantic} = resolved_root} ->
        if Value.type?(semantic) or ScaleStep.type?(semantic) do
          {:ok, resolved_root}
        else
          {:error, {:unsupported_realization, path}}
        end

      {:error, {:invalid_root_type, ^path} = reason} ->
        invalid_root_result(token_set, path, reason)

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp invalid_root_result(%TokenSet{tokens: tokens}, path, reason) do
    case Map.get(tokens, path) do
      %Token{resolution_status: :resolved, resolved_value: semantic} ->
        if fluid_tag?(semantic) do
          {:error, reason}
        else
          {:error, {:unsupported_realization, path}}
        end

      _other ->
        {:error, reason}
    end
  end

  defp fluid_tag?(%{"type" => type}) when is_binary(type), do: String.starts_with?(type, "fluid_")
  defp fluid_tag?(_semantic), do: false

  defp add_domain_dependency(acc, name, domain) do
    fallback = %{name: name, expression: fallback_progress(domain)}
    modern = %{name: name, expression: modern_progress(domain)}

    acc
    |> Map.update!(:fallback_dependencies, &Map.put_new(&1, name, fallback))
    |> Map.update!(:modern_overrides, &Map.put_new(&1, name, modern))
  end

  defp add_scale_dependencies(acc, scale_path, scale, domain_name) do
    {base_name, ratio_name} = scale_variable_names(scale_path)

    base = %{
      name: base_name,
      expression: scale_base_expression(scale, "var(#{domain_name})")
    }

    ratio = %{
      name: ratio_name,
      expression: scale_ratio_expression(scale, "var(#{domain_name})")
    }

    Map.update!(acc, :fallback_dependencies, fn dependencies ->
      dependencies
      |> Map.put_new(base_name, base)
      |> Map.put_new(ratio_name, ratio)
    end)
  end

  defp sort_plan(acc) do
    %{
      fallback_dependencies: acc.fallback_dependencies |> Map.values() |> Enum.sort_by(& &1.name),
      modern_overrides: acc.modern_overrides |> Map.values() |> Enum.sort_by(& &1.name),
      values: acc.values |> Map.values() |> Enum.sort_by(& &1.path)
    }
  end

  defp domain_variable_name(path) do
    "--lf-fluid-domain-" <> String.replace(path, ".", "-") <> "-progress"
  end

  defp scale_variable_names(path) do
    slug = String.replace(path, ".", "-")

    {
      "--lf-fluid-scale-" <> slug <> "-base",
      "--lf-fluid-scale-" <> slug <> "-ratio"
    }
  end

  defp fallback_progress(domain) do
    start = format_typed_value(domain["start"])
    finish = format_typed_value(domain["end"])

    "clamp(0, tan(atan2(calc(100vw - #{start}), calc(#{finish} - #{start}))), 1)"
  end

  defp modern_progress(domain) do
    start = format_typed_value(domain["start"])
    finish = format_typed_value(domain["end"])

    "progress(100vw, #{start}, #{finish})"
  end

  defp value_expression(semantic, progress) do
    start = format_typed_value(semantic["start_value"])
    finish = format_typed_value(semantic["end_value"])

    "calc(#{start} + ((#{finish} - #{start}) * #{progress}))"
  end

  defp scale_base_expression(scale, progress) do
    start = format_typed_value(scale["base_start"])
    finish = format_typed_value(scale["base_end"])

    "calc(#{start} + ((#{finish} - #{start}) * #{progress}))"
  end

  defp scale_ratio_expression(scale, progress) do
    start = format_number(scale["ratio_start"])
    finish = format_number(scale["ratio_end"])

    "calc(#{start} + ((#{finish} - #{start}) * #{progress}))"
  end

  defp scale_step_expression(base_name, ratio_name, power) do
    "calc(var(#{base_name}) * pow(var(#{ratio_name}), #{power}))"
  end

  defp format_typed_value(value) when is_integer(value), do: format_number(value)
  defp format_typed_value(value) when is_float(value), do: format_number(value)

  defp format_typed_value(%{"value" => value, "unit" => unit})
       when is_number(value) and unit in ["px", "rem"] do
    format_number(value) <> unit
  end

  defp format_number(value) when is_integer(value), do: Integer.to_string(value)

  defp format_number(value) when is_float(value) do
    if value == 0.0 do
      "0"
    else
      :erlang.float_to_binary(value, [:short])
    end
  end
end
