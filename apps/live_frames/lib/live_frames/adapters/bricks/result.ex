defmodule LiveFrames.Adapters.Bricks.Result do
  @moduledoc """
  Plain result/status data for the Bricks extraction lifecycle.
  """

  alias LiveFrames.Adapters.Bricks.Diagnostic

  @active_states [
    :received,
    :recognized,
    :validated,
    :resolved,
    :tree_built,
    :dependencies_extracted,
    :rendered,
    :verified
  ]

  @terminal_states [:completed, :rejected, :failed]

  @states @active_states ++ @terminal_states

  @happy_next %{
    received: :recognized,
    recognized: :validated,
    validated: :resolved,
    resolved: :tree_built,
    tree_built: :dependencies_extracted,
    dependencies_extracted: :rendered,
    rendered: :verified,
    verified: :completed
  }

  @exceptional_targets [:rejected, :failed]

  @allowed_transitions Enum.reduce(@active_states, %{}, fn state, acc ->
                         happy = Map.fetch!(@happy_next, state)
                         Map.put(acc, state, [happy | @exceptional_targets])
                       end)
                       |> Map.merge(%{completed: [], rejected: [], failed: []})

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

  @spec active_states() :: [atom()]
  def active_states, do: @active_states

  @spec terminal_states() :: [atom()]
  def terminal_states, do: @terminal_states

  @spec allowed_transitions() :: %{atom() => [atom()]}
  def allowed_transitions, do: @allowed_transitions

  @spec terminal?(t() | atom()) :: boolean()
  def terminal?(%__MODULE__{status: status}), do: terminal?(status)

  def terminal?(state) when state in @terminal_states, do: true
  def terminal?(state) when state in @active_states, do: false
  def terminal?(_), do: false

  @spec new(keyword()) :: t()
  def new(attrs \\ []) when is_list(attrs) do
    if Keyword.has_key?(attrs, :status) do
      raise ArgumentError, "Result.new/1 does not accept lifecycle-owned field :status"
    end

    if Keyword.has_key?(attrs, :lifecycle) do
      raise ArgumentError, "Result.new/1 does not accept lifecycle-owned field :lifecycle"
    end

    struct(__MODULE__, attrs)
  end

  @spec advance(t(), atom()) :: t()
  def advance(%__MODULE__{status: status} = result, next) when next in @states do
    if terminal?(status) do
      raise transition_error(status, next)
    end

    case Map.get(@happy_next, status) do
      ^next -> %{result | status: next, lifecycle: result.lifecycle ++ [next]}
      _ -> raise transition_error(status, next)
    end
  end

  def advance(%__MODULE__{status: status}, next),
    do: raise(transition_error(status, next))

  @spec reject(t(), [Diagnostic.t()]) :: t()
  def reject(%__MODULE__{status: status} = result, diagnostics) do
    if terminal?(status) do
      raise transition_error(status, :rejected)
    end

    %{
      result
      | status: :rejected,
        lifecycle: result.lifecycle ++ [:rejected],
        diagnostics: result.diagnostics ++ diagnostics
    }
  end

  @spec fail(t(), [Diagnostic.t()]) :: t()
  def fail(%__MODULE__{status: status} = result, diagnostics) do
    if terminal?(status) do
      raise transition_error(status, :failed)
    end

    %{
      result
      | status: :failed,
        lifecycle: result.lifecycle ++ [:failed],
        diagnostics: result.diagnostics ++ diagnostics
    }
  end

  @spec add_diagnostics(t(), [Diagnostic.t()]) :: t()
  def add_diagnostics(%__MODULE__{} = result, diagnostics),
    do: %{result | diagnostics: result.diagnostics ++ diagnostics}

  defp transition_error(from, to) do
    ArgumentError.exception("invalid Bricks lifecycle transition from #{from} to #{to}")
  end
end
