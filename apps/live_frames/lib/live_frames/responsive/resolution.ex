defmodule LiveFrames.Responsive.Resolution do
  @moduledoc "A responsive IR override bound to validated breakpoint authority."

  alias LiveFrames.Fidelity.CSSDeclaration
  alias LiveFrames.IR.ResponsiveOverride
  alias LiveFrames.Responsive.BreakpointAuthority.Entry

  @type state ::
          :authority_missing
          | :authority_bound
          | :value_validated
          | :resolved
          | :serialized
          | :blocked
          | :rejected
          | :failed

  @type t :: %__MODULE__{
          node_id: String.t(),
          breakpoint_id: String.t() | nil,
          source_name: String.t() | nil,
          raw_styles: map(),
          authority: Entry.t() | nil,
          media_condition: String.t() | nil,
          declarations: [CSSDeclaration.t()],
          custom_css: String.t() | nil,
          serialized_css: String.t() | nil,
          state: state(),
          reason: atom() | nil
        }

  defstruct node_id: nil,
            breakpoint_id: nil,
            source_name: nil,
            raw_styles: %{},
            authority: nil,
            media_condition: nil,
            declarations: [],
            custom_css: nil,
            serialized_css: nil,
            state: :authority_missing,
            reason: nil

  @spec new(String.t(), ResponsiveOverride.t()) :: t()
  def new(node_id, %ResponsiveOverride{} = override) do
    %__MODULE__{
      node_id: node_id,
      breakpoint_id: override.breakpoint_id,
      source_name: override.source_name,
      raw_styles: override.styles
    }
  end

  @spec bind(t(), Entry.t()) :: {:ok, t()} | {:error, :invalid_transition}
  def bind(%__MODULE__{state: :authority_missing} = resolution, %Entry{} = authority) do
    {:ok,
     %{
       resolution
       | authority: authority,
         media_condition: authority.media_condition,
         state: :authority_bound
     }}
  end

  def bind(_resolution, _authority), do: {:error, :invalid_transition}

  @spec validate_value(t(), [CSSDeclaration.t()], String.t() | nil) ::
          {:ok, t()} | {:error, :invalid_transition | :invalid_value}
  def validate_value(
        %__MODULE__{state: :authority_bound} = resolution,
        declarations,
        custom_css
      )
      when is_list(declarations) and (is_nil(custom_css) or is_binary(custom_css)) do
    if Enum.all?(declarations, &(&1.state == :accepted)) do
      {:ok,
       %{
         resolution
         | declarations: declarations,
           custom_css: custom_css,
           state: :value_validated
       }}
    else
      {:error, :invalid_value}
    end
  end

  def validate_value(_resolution, _declarations, _custom_css),
    do: {:error, :invalid_transition}

  @spec resolve(t()) :: {:ok, t()} | {:error, :invalid_transition}
  def resolve(%__MODULE__{state: :value_validated} = resolution),
    do: {:ok, %{resolution | state: :resolved}}

  def resolve(_resolution), do: {:error, :invalid_transition}

  @spec serialize(t(), String.t()) :: {:ok, t()} | {:error, :invalid_transition}
  def serialize(%__MODULE__{state: :resolved} = resolution, css) when is_binary(css),
    do: {:ok, %{resolution | serialized_css: css, state: :serialized}}

  def serialize(_resolution, _css), do: {:error, :invalid_transition}

  @spec block(t(), atom()) :: {:ok, t()} | {:error, :invalid_transition}
  def block(%__MODULE__{state: state} = resolution, reason)
      when state in [:authority_missing, :authority_bound, :value_validated] and is_atom(reason),
      do: {:ok, %{resolution | reason: reason, state: :blocked}}

  def block(_resolution, _reason), do: {:error, :invalid_transition}

  @spec reject(t(), atom()) :: {:ok, t()} | {:error, :invalid_transition}
  def reject(%__MODULE__{state: state} = resolution, reason)
      when state in [:authority_missing, :authority_bound, :value_validated] and is_atom(reason),
      do: {:ok, %{resolution | reason: reason, state: :rejected}}

  def reject(_resolution, _reason), do: {:error, :invalid_transition}
end
