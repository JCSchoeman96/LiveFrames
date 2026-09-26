defmodule LiveFrames.StaticNavigation do
  @moduledoc """
  Source-neutral static navigation destination safety shared by adapters and Fidelity.

  Only corpus-proven static destination shapes are accepted. Unsafe schemes, dynamic
  template expressions, and malformed values are rejected without normalization.
  """

  @unsafe_scheme ~r/\A(?:javascript|data|vbscript):/i
  @dynamic_template ~r/\A\{[^}]+\}\z/
  @http_url ~r/\Ahttps?:\/\/[a-zA-Z0-9.-]+(?::\d+)?(?:\/[^\s]*)?\z/i
  @control_or_whitespace ~r/[\s\x00-\x1F\x7F]/

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

      Regex.match?(@http_url, value) ->
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
    not Regex.match?(@control_or_whitespace, value)
  end

  defp safe_fragment?(_value), do: false

  defp safe_site_path?(<<"/">>), do: true

  defp safe_site_path?(<<"/", rest::binary>>) do
    not String.starts_with?(rest, "/") and not Regex.match?(@control_or_whitespace, rest)
  end

  defp safe_site_path?(_value), do: false

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
