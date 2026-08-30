defmodule LiveFrames.IR.StyleValue do
  @moduledoc """
  Explicit tagged representation of a normalized style value.
  """

  @kinds [:literal, :token_ref, :calculation, :keyword, :responsive, :complex_css, :unresolved]

  @type kind ::
          :literal
          | :token_ref
          | :calculation
          | :keyword
          | :responsive
          | :complex_css
          | :unresolved

  @type t :: %__MODULE__{
          kind: kind() | atom(),
          value: term(),
          source_expression: String.t() | nil,
          source_trace: LiveFrames.IR.SourceTrace.t() | nil,
          metadata: map()
        }

  defstruct kind: nil, value: nil, source_expression: nil, source_trace: nil, metadata: %{}

  @spec kinds() :: [kind()]
  def kinds, do: @kinds

  @spec literal(term(), keyword()) :: t()
  def literal(value, opts \\ []), do: new(:literal, value, opts)

  @spec token_ref(String.t(), keyword()) :: t()
  def token_ref(path, opts \\ []), do: new(:token_ref, path, opts)

  @spec calculation(String.t(), keyword()) :: t()
  def calculation(expression, opts \\ []), do: new(:calculation, expression, opts)

  @spec keyword(String.t(), keyword()) :: t()
  def keyword(value, opts \\ []), do: new(:keyword, value, opts)

  @spec responsive(term(), keyword()) :: t()
  def responsive(value, opts \\ []), do: new(:responsive, value, opts)

  @spec complex_css(map(), keyword()) :: t()
  def complex_css(rules, opts \\ []), do: new(:complex_css, rules, opts)

  @spec unresolved(term(), keyword()) :: t()
  def unresolved(value, opts \\ []), do: new(:unresolved, value, opts)

  @spec new(kind(), term(), keyword()) :: t()
  def new(kind, value, opts \\ [])

  def new(kind, value, opts) when kind in @kinds and is_list(opts) do
    struct(__MODULE__,
      kind: kind,
      value: value,
      source_expression: Keyword.get(opts, :source_expression),
      source_trace: Keyword.get(opts, :source_trace),
      metadata: Keyword.get(opts, :metadata, %{})
    )
  end

  def new(kind, _value, _opts),
    do: raise(ArgumentError, "unsupported style value kind: #{inspect(kind)}")
end
