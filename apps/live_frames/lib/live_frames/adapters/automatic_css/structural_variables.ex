defmodule LiveFrames.Adapters.AutomaticCSS.StructuralVariables do
  @moduledoc """
  Automatic.css structural-variable authority for supported source versions.

  This boundary records proven structural CSS recipes such as grid variables.
  It does not read source filesystems at runtime.
  """

  alias LiveFrames.Styles.StructuralVariableAuthority

  @source_version "4.0.1"

  @grid_1_record %{
    "variable" => "--grid-1",
    "resolved_value" => "repeat(1, minmax(0, 1fr))",
    "authority_id" => "automatic-css-4.0.1:structural-grid:grid-1",
    "source_system" => "automatic_css",
    "source_version" => @source_version,
    "authority_type" => "PROJECT_SOURCE_ENVIRONMENT_GENERATED_CSS",
    "metadata" => %{}
  }

  @grid_2_record %{
    "variable" => "--grid-2",
    "resolved_value" => "repeat(2, minmax(0, 1fr))",
    "authority_id" => "automatic-css-4.0.1:structural-grid:grid-2",
    "source_system" => "automatic_css",
    "source_version" => @source_version,
    "authority_type" => "PROJECT_SOURCE_ENVIRONMENT_GENERATED_CSS",
    "metadata" => %{}
  }

  @grid_3_2_record %{
    "variable" => "--grid-3-2",
    "resolved_value" => "minmax(0, 3fr) minmax(0, 2fr)",
    "authority_id" => "automatic-css-4.0.1:structural-grid:grid-3-2",
    "source_system" => "automatic_css",
    "source_version" => @source_version,
    "authority_type" => "PROJECT_SOURCE_ENVIRONMENT_GENERATED_CSS",
    "metadata" => %{}
  }

  @grid_records [@grid_1_record, @grid_2_record, @grid_3_2_record]

  @spec authority(String.t(), keyword()) ::
          {:ok, StructuralVariableAuthority.t()} | {:error, :unsupported_source_version}
  def authority(@source_version, opts) when is_list(opts) do
    records = if grid_variables_enabled?(opts), do: @grid_records, else: []
    StructuralVariableAuthority.build(records)
  end

  def authority(_source_version, _opts), do: {:error, :unsupported_source_version}

  defp grid_variables_enabled?(opts) do
    case Keyword.get(opts, :grid_variables_enabled) do
      true -> true
      false -> false
      nil -> settings_grid_variables_enabled?(Keyword.get(opts, :settings))
    end
  end

  defp settings_grid_variables_enabled?(settings) when is_map(settings) do
    case Map.get(settings, "option-grid-variables") do
      "on" -> true
      _other -> false
    end
  end

  defp settings_grid_variables_enabled?(_settings), do: false
end
