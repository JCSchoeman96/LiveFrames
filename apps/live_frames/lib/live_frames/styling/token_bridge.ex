defmodule LiveFrames.Styling.TokenBridge do
  @moduledoc false

  alias LiveFrames.Tokens.Token
  alias LiveFrames.Tokens.TokenSet

  @css_variable ~r/^--lf-[a-z0-9]+(?:-[a-z0-9]+)*$/
  @unsafe_value ~r/[{};\\]/
  @unsafe_external_url ~r/url\s*\(\s*(?:["']\s*|\/\*.*?\*\/\s*)*(?:https?:|\/\/|javascript:)/is

  @spec load_mapping!(binary()) :: map()
  def load_mapping!(path) when is_binary(path) do
    path
    |> File.read!()
    |> Jason.decode!()
    |> validate_mapping_structure!()
  end

  @spec generate(TokenSet.t(), map()) :: {:ok, String.t()} | {:error, term()}
  def generate(%TokenSet{} = token_set, mapping) when is_map(mapping) do
    with :ok <- validate_mapping(token_set, mapping) do
      mapping["entries"]
      |> Enum.sort_by(&entry_sort_key/1)
      |> Enum.reduce_while({:ok, []}, fn entry, {:ok, acc} ->
        case declaration_for(entry, token_set) do
          {:error, _} = error -> {:halt, error}
          line -> {:cont, {:ok, [line | acc]}}
        end
      end)
      |> case do
        {:error, _} = error -> error
        {:ok, lines} -> {:ok, format_stylesheet(Enum.reverse(lines))}
      end
    end
  end

  defp validate_mapping_structure!(mapping) when is_map(mapping) do
    unless is_list(mapping["entries"]) do
      raise ArgumentError, "token mapping must include entries list"
    end

    mapping
  end

  defp validate_mapping(token_set, mapping) do
    entries = mapping["entries"] || []

    with :ok <- validate_duplicate_paths(entries),
         :ok <- validate_duplicate_css_variables(entries),
         :ok <- validate_duplicate_tailwind_aliases(entries) do
      validate_entries_resolvable(token_set, entries)
    end
  end

  defp validate_duplicate_paths(entries) do
    paths =
      entries
      |> Enum.flat_map(fn
        %{"token_set_path" => path} when is_binary(path) -> [path]
        _ -> []
      end)

    case duplicate_values(paths) do
      [] -> :ok
      dupes -> {:error, {:duplicate_token_set_paths, dupes}}
    end
  end

  defp validate_duplicate_css_variables(entries) do
    case duplicate_values(Enum.map(entries, & &1["css_variable"])) do
      [] -> :ok
      dupes -> {:error, {:duplicate_css_variables, dupes}}
    end
  end

  defp validate_duplicate_tailwind_aliases(entries) do
    aliases =
      entries
      |> Enum.map(& &1["tailwind_alias"])
      |> Enum.reject(&is_nil/1)

    case duplicate_values(aliases) do
      [] -> :ok
      dupes -> {:error, {:duplicate_tailwind_aliases, dupes}}
    end
  end

  defp validate_entries_resolvable(token_set, entries) do
    Enum.reduce_while(entries, :ok, fn entry, :ok ->
      case resolve_entry(entry, token_set) do
        {:ok, _name, _value} -> {:cont, :ok}
        {:error, _} = error -> {:halt, error}
      end
    end)
  end

  defp declaration_for(entry, token_set) do
    case resolve_entry(entry, token_set) do
      {:ok, name, value} ->
        case safe_css_value?(value) do
          true -> "  #{name}: #{value};"
          false -> {:error, {:unsafe_css_value, name, value}}
        end

      {:error, _} = error ->
        error
    end
  end

  defp resolve_entry(%{"css_variable" => name} = entry, token_set) do
    cond do
      not css_variable?(name) ->
        {:error, {:invalid_css_variable, name}}

      true ->
        case entry do
          %{"compose" => %{"type" => "fluid_px_pair"} = compose} ->
            fluid_px_pair(token_set, name, compose)

          %{"token_set_path" => path} ->
            token_value(token_set, name, path)

          _ ->
            {:error, {:invalid_mapping_entry, entry}}
        end
    end
  end

  defp resolve_entry(entry, _token_set), do: {:error, {:invalid_mapping_entry, entry}}

  defp token_value(token_set, name, path) do
    case Map.fetch(token_set.tokens, path) do
      :error ->
        {:error, {:missing_token, path}}

      {:ok, %Token{resolution_status: :resolved} = token} ->
        case css_value(token) do
          {:ok, value} -> {:ok, name, value}
          {:error, reason} -> {:error, {reason, path}}
        end

      {:ok, %Token{resolution_status: status}} ->
        {:error, {:unresolved_token, path, status}}
    end
  end

  defp fluid_px_pair(token_set, name, compose) do
    with {:ok, min_px} <- token_px(token_set, compose["min"]),
         {:ok, max_px} <- token_px(token_set, compose["max"]),
         {:ok, viewport_min} <- token_px(token_set, compose["viewport_min"]),
         {:ok, viewport_max} <- token_px(token_set, compose["viewport_max"]),
         css when is_binary(css) <-
           clamp_from_px(min_px, max_px, viewport_min, viewport_max) do
      {:ok, name, css}
    else
      {:error, reason} -> {:error, reason}
      _ -> {:error, {:invalid_fluid_px_pair, name}}
    end
  end

  defp css_value(%Token{metadata: %{"css_expression" => css}}) when is_binary(css),
    do: {:ok, css}

  defp css_value(%Token{resolved_value: value}) when is_binary(value), do: {:ok, value}

  defp css_value(%Token{resolved_value: value}) when is_integer(value),
    do: {:ok, Integer.to_string(value)}

  defp css_value(%Token{resolved_value: value}) when is_float(value),
    do: {:ok, format_float(value)}

  defp css_value(%Token{resolved_value: %{"type" => "responsive", "min" => min, "max" => max}})
       when is_binary(min) and is_binary(max),
       do: {:ok, "clamp(#{min}, #{max}, #{max})"}

  defp css_value(_token), do: {:error, :non_serializable_resolved_value}

  defp token_px(token_set, path) do
    case Map.fetch(token_set.tokens, path) do
      :error ->
        {:error, {:missing_token, path}}

      {:ok, %Token{resolution_status: :resolved, resolved_value: value}} ->
        parse_px(value, path)

      {:ok, %Token{resolution_status: status}} ->
        {:error, {:unresolved_token, path, status}}
    end
  end

  defp parse_px(value, path) when is_binary(value) do
    case Regex.run(~r/^(-?\d+(?:\.\d+)?)px$/, value) do
      [_, number] ->
        case Float.parse(number) do
          {float, ""} -> {:ok, float}
          _ -> {:error, {:invalid_px_token, path, value}}
        end

      _ ->
        {:error, {:invalid_px_token, path, value}}
    end
  end

  defp parse_px(value, path), do: {:error, {:invalid_px_token, path, value}}

  defp clamp_from_px(min_px, max_px, viewport_min_px, viewport_max_px)
       when is_number(min_px) and is_number(max_px) and is_number(viewport_min_px) and
              is_number(viewport_max_px) and viewport_max_px > viewport_min_px do
    root_px = 16.0
    min_rem = min_px / root_px
    max_rem = max_px / root_px
    vp_min = viewport_min_px / root_px
    vp_max = viewport_max_px / root_px
    slope = (max_rem - min_rem) / (vp_max - vp_min)
    slope_vw = slope * 100
    intercept = min_rem - slope * vp_min

    "clamp(#{format_float(min_rem)}rem, calc(#{format_float(slope_vw)}vw + #{format_float(intercept)}rem), #{format_float(max_rem)}rem)"
  end

  defp clamp_from_px(_, _, _, _), do: nil

  defp css_variable?(name) when is_binary(name), do: Regex.match?(@css_variable, name)
  defp css_variable?(_), do: false

  defp safe_css_value?(value) when is_binary(value) do
    not Regex.match?(@unsafe_value, value) and not Regex.match?(@unsafe_external_url, value)
  end

  defp safe_css_value?(_), do: false

  defp entry_sort_key(%{"css_variable" => name}), do: name
  defp entry_sort_key(_), do: ""

  defp duplicate_values(values) do
    values
    |> Enum.frequencies()
    |> Enum.filter(fn {_value, count} -> count > 1 end)
    |> Enum.map(&elem(&1, 0))
    |> Enum.sort()
  end

  defp format_stylesheet(lines) when is_list(lines) do
    header = "/* Generated by LiveFrames.Styling.TokenBridge — do not edit. */\n"
    body = Enum.join(lines, "\n")
    header <> ":root {\n" <> body <> "\n}\n"
  end

  defp format_float(value) when is_float(value) do
    value
    |> :erlang.float_to_binary(decimals: 10)
    |> String.trim_trailing("0")
    |> String.trim_trailing(".")
  end
end
