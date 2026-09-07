defmodule LiveFrames.Adapters.Bricks.ThemeStyles do
  @moduledoc """
  Minimal Bricks Theme Styles binding for container width authority.

  Loads the active style's `settings.container.width` only. This is not a
  general Theme Styles or CSS cascade engine.
  """

  @spec from_file(Path.t()) :: {:ok, map()} | {:error, term()}
  def from_file(path) when is_binary(path) do
    with {:ok, bytes} <- File.read(path),
         {:ok, decoded} <- Jason.decode(bytes) do
      from_map(decoded)
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @spec from_map(term()) :: {:ok, map()} | {:error, term()}
  def from_map(%{"source" => "bricks_theme_styles"} = map), do: {:ok, normalize(map)}
  def from_map(%{source: "bricks_theme_styles"} = map), do: from_map(stringify(map))
  def from_map(_other), do: {:error, :invalid_theme_styles}

  @spec container_width(map() | nil) ::
          {:ok, String.t()} | :absent | {:invalid, term()}
  def container_width(nil), do: :absent

  def container_width(theme_styles) when is_map(theme_styles) do
    active_id =
      Map.get(theme_styles, "active_style_id") || Map.get(theme_styles, :active_style_id)

    styles = Map.get(theme_styles, "styles") || Map.get(theme_styles, :styles) || %{}

    style =
      cond do
        is_binary(active_id) -> Map.get(styles, active_id) || %{}
        true -> %{}
      end

    settings = Map.get(style, "settings") || Map.get(style, :settings) || %{}
    container = Map.get(settings, "container") || Map.get(settings, :container) || %{}
    width = Map.get(container, "width") || Map.get(container, :width)

    case width do
      nil -> :absent
      "" -> :absent
      value when is_binary(value) -> {:ok, value}
      other -> {:invalid, other}
    end
  end

  def container_width(_other), do: :absent

  defp normalize(map) do
    %{
      "source" => "bricks_theme_styles",
      "active_style_id" => Map.get(map, "active_style_id"),
      "styles" => Map.get(map, "styles") || %{}
    }
  end

  defp stringify(map) when is_map(map) do
    Map.new(map, fn
      {key, value} when is_atom(key) -> {Atom.to_string(key), stringify(value)}
      {key, value} -> {key, stringify(value)}
    end)
  end

  defp stringify(list) when is_list(list), do: Enum.map(list, &stringify/1)
  defp stringify(other), do: other
end
