defmodule LiveFrames.IR.DesignNode do
  @moduledoc """
  A semantic node in the Design IR tree.
  """

  @semantic_types ~w(
    section container wrapper stack grid generic
    heading paragraph rich_text image icon button link
    actions background overlay raw unsupported unknown
  )

  @type t :: %__MODULE__{
          node_id: String.t() | nil,
          semantic_type: String.t() | nil,
          semantic_role: String.t() | nil,
          label: String.t() | nil,
          content: term(),
          attributes: map(),
          styles: map(),
          responsive: map(),
          interaction_refs: [String.t()],
          asset_refs: [String.t()],
          children: [t()],
          source_trace: LiveFrames.IR.SourceTrace.t() | nil
        }

  defstruct node_id: nil,
            semantic_type: nil,
            semantic_role: nil,
            label: nil,
            content: nil,
            attributes: %{},
            styles: %{},
            responsive: %{},
            interaction_refs: [],
            asset_refs: [],
            children: [],
            source_trace: nil

  @spec semantic_types() :: [String.t()]
  def semantic_types, do: @semantic_types

  @spec deterministic_id([pos_integer()]) :: String.t()
  def deterministic_id(path) when is_list(path) do
    if path != [] and Enum.all?(path, &(is_integer(&1) and &1 > 0)) do
      suffix = Enum.map_join(path, "_", &String.pad_leading(Integer.to_string(&1), 6, "0"))
      "node_" <> suffix
    else
      raise ArgumentError, "node path must be a non-empty list of positive integers"
    end
  end

  def deterministic_id(_path),
    do: raise(ArgumentError, "node path must be a non-empty list of positive integers")

  @spec new([pos_integer()], keyword()) :: t()
  def new(path, attrs \\ []) when is_list(path) and is_list(attrs) do
    struct(__MODULE__, Keyword.put(attrs, :node_id, deterministic_id(path)))
  end
end
