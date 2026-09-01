defmodule LiveFrames.Adapters.Bricks.Diagnostic do
  @moduledoc """
  A structured finding produced while interpreting untrusted Bricks data.
  """

  @type severity :: :info | :warning | :error | :fatal

  @type t :: %__MODULE__{
          code: String.t() | nil,
          severity: severity(),
          category: atom() | String.t() | nil,
          message: String.t() | nil,
          source_path: String.t() | nil,
          source_id: String.t() | nil,
          raw_value: term(),
          metadata: map()
        }

  defstruct code: nil,
            severity: :error,
            category: nil,
            message: nil,
            source_path: nil,
            source_id: nil,
            raw_value: nil,
            metadata: %{}

  @severities [:info, :warning, :error, :fatal]

  @spec new(keyword()) :: t()
  def new(attrs \\ []) when is_list(attrs) do
    attrs =
      attrs
      |> Keyword.put(:severity, normalize_severity(Keyword.get(attrs, :severity, :error)))
      |> Keyword.put_new(:category, category_from_code(Keyword.get(attrs, :code)))

    struct(__MODULE__, attrs)
  end

  @spec normalize_severity(term()) :: severity()
  def normalize_severity(severity) when severity in @severities, do: severity

  def normalize_severity(severity) when is_binary(severity) do
    case severity do
      "info" -> :info
      "warning" -> :warning
      "error" -> :error
      "fatal" -> :fatal
      _ -> :error
    end
  end

  def normalize_severity(_), do: :error

  defp category_from_code(code) when is_binary(code) do
    case String.split(code, ".") do
      ["bricks", category | _] -> category
      _ -> nil
    end
  end

  defp category_from_code(_), do: nil
end
