defmodule LiveFrames.Adapters.Bricks.Result do
  @moduledoc """
  Plain result/status data for the Bricks extraction lifecycle.
  """

  alias LiveFrames.Adapters.Bricks.Diagnostic

  @states [
    :received,
    :recognized,
    :validated,
    :resolved,
    :tree_built,
    :dependencies_extracted,
    :rendered,
    :verified,
    :completed
  ]

  @next_states %{
    received: :recognized,
    recognized: :validated,
    validated: :resolved,
    resolved: :tree_built,
    tree_built: :dependencies_extracted,
    dependencies_extracted: :rendered,
    rendered: :verified,
    verified: :completed
  }

  @type t :: %__MODULE__{
          status: atom(),
          lifecycle: [atom()],
          document: term(),
          proxy: term(),
          component: term(),
          tree: term(),
          dependencies: term(),
          artifacts: map(),
          artifact_paths: map(),
          report: map() | nil,
          diagnostics: [Diagnostic.t()]
        }

  defstruct status: :received,
            lifecycle: [:received],
            document: nil,
            proxy: nil,
            component: nil,
            tree: nil,
            dependencies: [],
            artifacts: %{},
            artifact_paths: %{},
            report: nil,
            diagnostics: []

  @spec states() :: [atom()]
  def states, do: @states

  @spec new(keyword()) :: t()
  def new(attrs \\ []) when is_list(attrs), do: struct(__MODULE__, attrs)

  @spec advance(t(), atom()) :: t()
  def advance(%__MODULE__{status: status} = result, next) when next in @states do
    case Map.get(@next_states, status) do
      ^next -> %{result | status: next, lifecycle: result.lifecycle ++ [next]}
      _ -> raise ArgumentError, "invalid Bricks lifecycle transition from #{status} to #{next}"
    end
  end

  def advance(_result, next),
    do: raise(ArgumentError, "invalid Bricks lifecycle state: #{inspect(next)}")

  @spec reject(t(), [Diagnostic.t()]) :: t()
  def reject(%__MODULE__{} = result, diagnostics),
    do: %{result | status: :rejected, diagnostics: result.diagnostics ++ diagnostics}

  @spec fail(t(), [Diagnostic.t()]) :: t()
  def fail(%__MODULE__{} = result, diagnostics),
    do: %{result | status: :failed, diagnostics: result.diagnostics ++ diagnostics}

  @spec add_diagnostics(t(), [Diagnostic.t()]) :: t()
  def add_diagnostics(%__MODULE__{} = result, diagnostics),
    do: %{result | diagnostics: result.diagnostics ++ diagnostics}
end
