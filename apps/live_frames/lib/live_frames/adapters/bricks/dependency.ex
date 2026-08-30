defmodule LiveFrames.Adapters.Bricks.Dependency do
  @moduledoc """
  A preserved or resolved dependency found in Bricks source data.
  """

  @statuses [
    :resolved_token,
    :source_variable,
    :unresolved_external,
    :unresolved,
    :preserved,
    :unsupported
  ]

  @type t :: %__MODULE__{
          kind: atom() | String.t(),
          status: atom() | String.t(),
          name: String.t() | nil,
          raw_value: term(),
          source_path: String.t() | nil,
          source_id: String.t() | nil,
          metadata: map()
        }

  defstruct kind: nil,
            status: :preserved,
            name: nil,
            raw_value: nil,
            source_path: nil,
            source_id: nil,
            metadata: %{}

  @spec statuses() :: [atom()]
  def statuses, do: @statuses

  @spec new(keyword()) :: t()
  def new(attrs \\ []) when is_list(attrs), do: struct(__MODULE__, attrs)
end
