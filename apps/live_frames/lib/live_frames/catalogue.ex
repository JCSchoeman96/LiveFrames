defmodule LiveFrames.Catalogue do
  @moduledoc """
  Provides static discovery for consumer-visible Catalogue manifests.
  """

  alias LiveFrames.Catalogue.Discovery
  alias LiveFrames.Catalogue.Manifest
  alias LiveFrames.Catalogue.Registry

  @spec list() :: [Manifest.t()]
  def list, do: Registry.all() |> Discovery.filter(:released)

  @spec list(:released | :released_and_deprecated) :: [Manifest.t()]
  def list(mode), do: Registry.all() |> Discovery.filter(mode)

  @spec fetch(term()) :: {:ok, Manifest.t()} | :error
  def fetch(id), do: id |> Registry.fetch() |> Discovery.visible_fetch()
end
