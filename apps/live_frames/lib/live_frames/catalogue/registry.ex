defmodule LiveFrames.Catalogue.Registry do
  @moduledoc false

  alias LiveFrames.Catalogue.Registry.Compilation

  @source_root Path.expand("../../../priv/catalogue", __DIR__)
  registry_data = Compilation.prepare!(@source_root)

  for resource <- registry_data.external_resources do
    @external_resource resource
  end

  @manifests registry_data.manifests
  @manifest_by_id Map.new(@manifests, &{&1.id, &1})
  @compiled_membership_signature registry_data.membership_signature

  @spec all() :: [LiveFrames.Catalogue.Manifest.t()]
  def all, do: @manifests

  @spec fetch(term()) :: {:ok, LiveFrames.Catalogue.Manifest.t()} | :error
  def fetch(id) when is_binary(id), do: Map.fetch(@manifest_by_id, id)
  def fetch(_id), do: :error

  @doc false
  def __mix_recompile__? do
    Compilation.membership_signature(@source_root) != @compiled_membership_signature
  end
end
