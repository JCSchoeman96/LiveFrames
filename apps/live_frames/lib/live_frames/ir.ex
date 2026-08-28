defmodule LiveFrames.IR do
  @moduledoc """
  Public API for constructing, validating, and serializing LiveFrames Design IR.
  """

  alias LiveFrames.IR.DesignDocument
  alias LiveFrames.IR.Diagnostic
  alias LiveFrames.IR.Serializer
  alias LiveFrames.IR.Validation
  alias LiveFrames.IR.ValidationError

  @spec validate(DesignDocument.t()) :: :ok | {:error, [Diagnostic.t()]}
  def validate(document), do: Validation.validate(document)

  @spec validate!(DesignDocument.t()) :: DesignDocument.t()
  def validate!(document) do
    case validate(document) do
      :ok ->
        document

      {:error, diagnostics} ->
        raise ValidationError, diagnostics: diagnostics
    end
  end

  @spec to_map(DesignDocument.t()) :: map()
  def to_map(document), do: Serializer.to_map(document)

  @spec encode(DesignDocument.t()) :: {:ok, String.t()} | {:error, [Diagnostic.t()]}
  def encode(document) do
    case validate(document) do
      :ok -> Serializer.encode(document)
      {:error, diagnostics} -> {:error, diagnostics}
    end
  end

  @spec encode!(DesignDocument.t()) :: String.t()
  def encode!(document) do
    document
    |> validate!()
    |> Serializer.encode!()
  end
end
