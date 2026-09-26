defmodule LiveFrames.StaticNavigation do
  @moduledoc """
  Source-neutral static navigation destination safety shared by adapters and Fidelity.

  Only corpus-proven static destination shapes are accepted. Unsafe schemes, dynamic
  template expressions, and malformed values are rejected without normalization.
  """

  @unsafe_scheme ~r/\A(?:javascript|data|vbscript):/i
  @dynamic_template ~r/\A\{[^}]+\}\z/
  @control_or_whitespace ~r/[\s\x00-\x1F\x7F]/
  @dns_label ~r/^[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?$/
  @max_dns_name_length 253
  @max_dns_label_length 63

  @spec classify_destination(term()) :: :safe | :unsafe | :malformed | :dynamic
  def classify_destination(value) when is_binary(value) do
    cond do
      value != String.trim(value) ->
        :malformed

      value == "" ->
        :malformed

      Regex.match?(@unsafe_scheme, value) ->
        :unsafe

      Regex.match?(@dynamic_template, value) ->
        :dynamic

      safe_fragment?(value) ->
        :safe

      safe_site_path?(value) ->
        :safe

      safe_http_url?(value) ->
        :safe

      true ->
        :malformed
    end
  end

  def classify_destination(_value), do: :malformed

  @spec protected_rel(String.t() | nil) :: String.t() | nil
  def protected_rel("_blank"), do: "noopener noreferrer"
  def protected_rel(_target), do: nil

  @doc """
  Validates a normalized navigation map from Design IR before emission.

  Returns attribute tuples in deterministic order: `href`, then `target`, then `rel`.
  The emitted `href` is exactly the validated source string (no rewriting).
  """
  @spec validate_navigation_map(map()) ::
          {:ok, [{String.t(), String.t()}]} | {:error, :missing | :unsafe | :malformed | :dynamic}
  def validate_navigation_map(%{"href" => href} = nav) when is_binary(href) do
    case classify_destination(href) do
      :safe ->
        {:ok, ordered_navigation_attrs(href, Map.get(nav, "target"))}

      :unsafe ->
        {:error, :unsafe}

      :dynamic ->
        {:error, :dynamic}

      :malformed ->
        {:error, :malformed}
    end
  end

  def validate_navigation_map(_nav), do: {:error, :missing}

  defp safe_fragment?(<<"#">>), do: true

  defp safe_fragment?(<<"#", _rest::binary>> = value) do
    not String.contains?(value, "\\") and not Regex.match?(@control_or_whitespace, value)
  end

  defp safe_fragment?(_value), do: false

  defp safe_site_path?(<<"/">>), do: true

  defp safe_site_path?(<<"/", rest::binary>>) do
    not String.starts_with?(rest, "/") and
      not String.contains?(rest, "\\") and
      not Regex.match?(@control_or_whitespace, rest)
  end

  defp safe_site_path?(_value), do: false

  defp safe_http_url?(value) do
    case Regex.run(~r/\Ahttps?:\/\/(.+)\z/i, value, capture: :all_but_first) do
      [remainder] ->
        not String.contains?(value, "\\") and
          not Regex.match?(@control_or_whitespace, value) and
          case split_http_remainder(remainder) do
            {:ok, host, port, path_suffix} ->
              valid_port?(port) and valid_ascii_host?(host) and
                valid_http_path_suffix?(path_suffix)

            :error ->
              false
          end

      _ ->
        false
    end
  end

  defp split_http_remainder(remainder) do
    case String.split(remainder, "/", parts: 2) do
      [authority] ->
        parse_authority(authority, "")

      [authority, path] ->
        parse_authority(authority, "/" <> path)
    end
  end

  defp parse_authority(authority, path_suffix) do
    cond do
      authority == "" or String.contains?(authority, "@") ->
        :error

      true ->
        case String.split(authority, ":", parts: 2) do
          [host] ->
            {:ok, host, nil, path_suffix}

          [host, port] ->
            if host != "" and port_digits_only?(port) do
              {:ok, host, port, path_suffix}
            else
              :error
            end

          _ ->
            :error
        end
    end
  end

  defp valid_http_path_suffix?(path_suffix) do
    path_suffix == "" or
      (String.starts_with?(path_suffix, "/") and
         not Regex.match?(@control_or_whitespace, path_suffix))
  end

  defp port_digits_only?(port), do: Regex.match?(~r/^\d+$/, port)

  defp valid_port?(nil), do: true

  defp valid_port?(port) when is_binary(port) do
    case Integer.parse(port) do
      {value, ""} when value >= 0 and value <= 65_535 -> true
      _ -> false
    end
  end

  defp valid_ascii_host?(host) do
    host != "" and byte_size(host) <= @max_dns_name_length and
      if ipv4_host?(host), do: valid_ipv4_host?(host), else: valid_dns_host?(host)
  end

  defp ipv4_host?(host), do: Regex.match?(~r/^(\d{1,3}\.){3}\d{1,3}$/, host)

  defp valid_ipv4_host?(host) do
    host
    |> String.split(".")
    |> Enum.all?(fn octet ->
      case Integer.parse(octet) do
        {value, ""} when value >= 0 and value <= 255 -> true
        _ -> false
      end
    end)
  end

  defp valid_dns_host?(host) do
    labels = String.split(host, ".")

    labels != [] and
      Enum.all?(labels, fn label ->
        byte_size(label) >= 1 and byte_size(label) <= @max_dns_label_length and
          Regex.match?(@dns_label, label)
      end)
  end

  defp ordered_navigation_attrs(href, target) do
    attrs = [{"href", href}]

    attrs =
      if target == "_blank" do
        attrs ++ [{"target", "_blank"}, {"rel", protected_rel("_blank")}]
      else
        attrs
      end

    Enum.sort_by(attrs, fn {name, _value} -> navigation_attr_order(name) end)
  end

  defp navigation_attr_order("href"), do: 0
  defp navigation_attr_order("target"), do: 1
  defp navigation_attr_order("rel"), do: 2
  defp navigation_attr_order(_name), do: 9
end
