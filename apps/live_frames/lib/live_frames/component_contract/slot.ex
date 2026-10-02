defmodule LiveFrames.ComponentContract.Slot do
  @moduledoc """
  Public slot declaration in a ComponentContract.
  """

  @first_wave_cardinality "0..1"

  @type t :: %__MODULE__{
          name: String.t() | nil,
          cardinality: String.t(),
          required: boolean(),
          semantic_purpose: String.t() | nil,
          consumer_responsibility: String.t() | nil,
          validation: map(),
          accessibility: map(),
          provenance: map()
        }

  defstruct name: nil,
            cardinality: @first_wave_cardinality,
            required: false,
            semantic_purpose: nil,
            consumer_responsibility: nil,
            validation: %{},
            accessibility: %{},
            provenance: %{}

  @spec first_wave_cardinality() :: String.t()
  def first_wave_cardinality, do: @first_wave_cardinality
end
