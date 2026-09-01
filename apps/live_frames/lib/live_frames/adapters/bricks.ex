defmodule LiveFrames.Adapters.Bricks do
  @moduledoc """
  Public source-specific boundary for Bricks copied-elements extraction.
  """

  alias LiveFrames.Adapters.Bricks.Document
  alias LiveFrames.Adapters.Bricks.Loader
  alias LiveFrames.Adapters.Bricks.Resolver
  alias LiveFrames.Adapters.Bricks.TreeBuilder

  @spec from_file(term(), keyword()) ::
          {:ok, Document.t(), list()} | {:error, list()}
  def from_file(path, opts \\ []), do: Loader.from_file(path, opts)

  @spec from_json(term(), keyword()) ::
          {:ok, Document.t(), list()} | {:error, list()}
  def from_json(json, opts \\ []), do: Loader.from_json(json, opts)

  @spec recognize(term(), keyword()) ::
          {:ok, Document.t(), list()} | {:error, list()}
  def recognize(source, opts \\ []), do: Loader.recognize(source, opts)

  @spec resolve(Document.t(), keyword() | map()) ::
          {:ok, term(), term(), list()} | {:error, list()}
  def resolve(document, opts \\ []), do: Resolver.resolve(document, opts)

  @spec build_tree(term()) :: {:ok, term(), list()} | {:error, list()}
  def build_tree(component), do: TreeBuilder.build(component)
end
