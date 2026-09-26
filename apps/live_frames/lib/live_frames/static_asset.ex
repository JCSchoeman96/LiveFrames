defmodule LiveFrames.StaticAsset do
  @moduledoc """
  Validates static image asset URIs without resolving hosts or rewriting values.
  """

  @dns_host ~r/\A[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?(?:\.[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?)*\z/
  @ipv4_host ~r/\A[0-9]+(?:\.[0-9]+){3}\z/
  @scheme ~r/\A([A-Za-z][A-Za-z0-9+.-]*):/
  @invalid_percent_escape ~r/%(?![A-Fa-f0-9]{2})/
  @unsafe_characters ~r/[\p{Cc}\p{Cf}\p{Z}]/u

  @type reason :: :missing | :dynamic | :unsafe | :malformed

  @spec validate(term(), keyword()) :: {:ok, String.t()} | {:error, reason()}
  def validate(uri, opts \\ [])

  def validate(uri, opts) when is_list(opts) do
    dynamic? = Keyword.get(opts, :dynamic?, false)

    cond do
      dynamic? ->
        {:error, :dynamic}

      uri in [nil, false, ""] ->
        {:error, :missing}

      not is_binary(uri) ->
        {:error, :malformed}

      not String.valid?(uri) ->
        {:error, :malformed}

      template_expression?(uri) ->
        {:error, :dynamic}

      unsafe_scheme?(uri) or String.starts_with?(uri, "//") or
        String.contains?(uri, "\\") or Regex.match?(@unsafe_characters, uri) ->
        {:error, :unsafe}

      String.contains?(uri, "?") or String.contains?(uri, "#") ->
        {:error, :dynamic}

      Regex.match?(@invalid_percent_escape, uri) ->
        {:error, :malformed}

      String.starts_with?(uri, "/") ->
        validate_site_path(uri)

      true ->
        validate_absolute_uri(uri)
    end
  end

  def validate(_uri, _opts), do: {:error, :malformed}

  defp template_expression?(uri),
    do: String.contains?(uri, "{") or String.contains?(uri, "}")

  defp unsafe_scheme?(uri) do
    case Regex.run(@scheme, uri, capture: :all_but_first) do
      [scheme] -> String.downcase(scheme) not in ["http", "https"]
      _ -> false
    end
  end

  defp validate_site_path(uri) do
    if uri != "/" and valid_path?(uri), do: {:ok, uri}, else: {:error, :malformed}
  end

  defp validate_absolute_uri(uri) do
    parsed = URI.parse(uri)

    if parsed.scheme in ["http", "https"] and valid_host?(parsed.host) and
         valid_port?(parsed.port) and is_nil(parsed.userinfo) and valid_path?(parsed.path) do
      {:ok, uri}
    else
      {:error, :malformed}
    end
  rescue
    _error in [URI.Error, ArgumentError] -> {:error, :malformed}
  end

  defp valid_host?(host) when is_binary(host) and byte_size(host) <= 253 do
    cond do
      Regex.match?(@ipv4_host, host) ->
        host
        |> String.split(".")
        |> Enum.all?(fn octet -> String.to_integer(octet) <= 255 end)

      true ->
        Regex.match?(@dns_host, host)
    end
  end

  defp valid_host?(_host), do: false

  defp valid_port?(nil), do: true
  defp valid_port?(port) when is_integer(port), do: port in 1..65_535
  defp valid_port?(_port), do: false

  defp valid_path?(path) when is_binary(path) and path != "" do
    String.starts_with?(path, "/") and
      not Regex.match?(~r/(?:\A|\/)\.{1,2}(?:\/|\z)/, path)
  end

  defp valid_path?(_path), do: false
end
