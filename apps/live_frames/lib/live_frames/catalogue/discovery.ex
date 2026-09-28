defmodule LiveFrames.Catalogue.Discovery do
  @moduledoc false

  alias LiveFrames.Catalogue.Manifest

  @type mode :: :released | :released_and_deprecated

  @spec filter([Manifest.t()], mode()) :: [Manifest.t()]
  def filter(manifests, :released) do
    Enum.filter(manifests, &(&1.state == "RELEASED"))
  end

  def filter(manifests, :released_and_deprecated) do
    Enum.filter(manifests, &(&1.state in ["RELEASED", "DEPRECATED"]))
  end

  def filter(_manifests, _mode) do
    raise ArgumentError, "unsupported Catalogue discovery mode"
  end

  @spec visible_fetch({:ok, Manifest.t()} | :error) :: {:ok, Manifest.t()} | :error
  def visible_fetch(:error), do: :error

  def visible_fetch({:ok, %Manifest{state: state} = manifest})
      when state in ["RELEASED", "DEPRECATED"],
      do: {:ok, manifest}

  def visible_fetch({:ok, %Manifest{}}), do: :error
end
