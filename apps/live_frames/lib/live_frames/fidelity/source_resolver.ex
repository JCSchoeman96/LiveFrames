defmodule LiveFrames.Fidelity.SourceResolver do
  @moduledoc "Generic contract for source-specific fidelity declarations."

  @callback resolve([String.t()], map()) :: %{
              optional(:resolver_id) => String.t(),
              declarations: list(),
              consumed_hints: [String.t()]
            }

  defmodule Noop do
    @moduledoc false
    @behaviour LiveFrames.Fidelity.SourceResolver

    @impl true
    def resolve(_classes, _token_set),
      do: %{resolver_id: "noop", declarations: [], consumed_hints: []}
  end
end
