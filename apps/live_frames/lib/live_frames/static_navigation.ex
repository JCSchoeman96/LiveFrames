defmodule LiveFrames.StaticNavigation do
  @moduledoc """
  Source-neutral static navigation destination safety shared by adapters and Fidelity.

  Only corpus-proven static destination shapes are accepted. Unsafe schemes, dynamic
  template expressions, and malformed values are rejected without normalization.
  """

  @unsafe_scheme ~r/\A(?:javascript|data|vbscript):/i
  @dynamic_template ~r/\A\{[^}]+\}\z/
  @http_url ~r/\Ahttps?:\/\/\S+\z/i
  @site_path ~r/\A\/\S*\z/

  @spec classify_destination(term()) :: :safe | :unsafe | :malformed | :dynamic
  def classify_destination(value) when is_binary(value) do
    destination = String.trim(value)

    cond do
      destination == "" ->
        :malformed

      Regex.match?(@unsafe_scheme, destination) ->
        :unsafe

      Regex.match?(@dynamic_template, destination) ->
        :dynamic

      String.starts_with?(destination, "#") ->
        :safe

      Regex.match?(@site_path, destination) ->
        :safe

      Regex.match?(@http_url, destination) ->
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
