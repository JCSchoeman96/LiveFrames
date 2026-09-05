defmodule LiveFrames.Fidelity.SourceResolver do
  @moduledoc "Generic contract for source-specific fidelity declarations."

  @type context :: %{
          optional(:semantic_type) => String.t() | nil,
          optional(:tag) => String.t() | nil,
          optional(:node_id) => String.t() | nil
        }

  @type result :: %{
          optional(:resolver_id) => String.t(),
          declarations: list(),
          consumed_hints: [String.t()]
        }

  @callback resolve([String.t()], map()) :: result
  @callback resolve([String.t()], map(), context()) :: result

  @optional_callbacks resolve: 3

  defmodule Noop do
    @moduledoc false
    @behaviour LiveFrames.Fidelity.SourceResolver

    @impl true
    def resolve(_classes, _token_set),
      do: %{resolver_id: "noop", declarations: [], consumed_hints: []}

    @impl true
    def resolve(classes, token_set, _context), do: resolve(classes, token_set)
  end
end
