defmodule LiveFrames.Styling.Fluid.Resolver do
  @moduledoc """
  Resolves Fluid semantic dependencies from an indexed TokenSet at compile time.
  """

  alias LiveFrames.Styling.Fluid.Domain
  alias LiveFrames.Styling.Fluid.Scale
  alias LiveFrames.Styling.Fluid.ScaleStep
  alias LiveFrames.Styling.Fluid.Value
  alias LiveFrames.Tokens.Token
  alias LiveFrames.Tokens.TokenSet

  @type reason ::
          {:token_not_found, String.t()}
          | {:unresolved_dependency, String.t()}
          | {:invalid_root_type, String.t()}
          | {:invalid_dependency_type, String.t(), String.t()}

  @spec resolve(TokenSet.t(), String.t()) :: {:ok, map()} | {:error, reason()}
  def resolve(%TokenSet{tokens: tokens}, path) when is_binary(path) do
    with {:ok, semantic} <- fetch_semantic(tokens, path) do
      resolve_semantic(tokens, path, semantic)
    end
  end

  defp resolve_semantic(tokens, path, semantic) do
    case fluid_type(semantic) do
      "fluid_domain" -> {:ok, %{semantic: semantic}}
      "fluid_value" -> resolve_value(tokens, semantic)
      "fluid_scale" -> resolve_scale(tokens, semantic)
      "fluid_scale_step" -> resolve_scale_step(tokens, semantic)
      _unknown -> {:error, {:invalid_root_type, path}}
    end
  end

  defp resolve_value(tokens, semantic) do
    with {:ok, domain} <- fetch_dependency(tokens, semantic["domain_ref"], "fluid_domain") do
      {:ok, %{semantic: semantic, domain: domain}}
    end
  end

  defp resolve_scale(tokens, semantic) do
    with {:ok, domain} <- fetch_dependency(tokens, semantic["domain_ref"], "fluid_domain") do
      {:ok, %{semantic: semantic, domain: domain}}
    end
  end

  defp resolve_scale_step(tokens, semantic) do
    with {:ok, scale} <- fetch_dependency(tokens, semantic["scale_ref"], "fluid_scale"),
         {:ok, domain} <- fetch_dependency(tokens, scale["domain_ref"], "fluid_domain") do
      {:ok, %{semantic: semantic, scale: scale, domain: domain}}
    end
  end

  defp fetch_semantic(tokens, path) do
    case Map.fetch(tokens, path) do
      :error ->
        {:error, {:token_not_found, path}}

      {:ok, token} ->
        resolved_semantic(token, path)
    end
  end

  defp fetch_dependency(tokens, path, expected_type) do
    with {:ok, semantic} <- fetch_semantic(tokens, path) do
      if fluid_type(semantic) == expected_type do
        {:ok, semantic}
      else
        {:error, {:invalid_dependency_type, path, expected_type}}
      end
    end
  end

  defp resolved_semantic(
         %Token{resolution_status: :resolved, resolved_value: semantic},
         _path
       )
       when not is_nil(semantic),
       do: {:ok, semantic}

  defp resolved_semantic(_token, path), do: {:error, {:unresolved_dependency, path}}

  defp fluid_type(semantic) do
    cond do
      Domain.type?(semantic) -> "fluid_domain"
      Value.type?(semantic) -> "fluid_value"
      Scale.type?(semantic) -> "fluid_scale"
      ScaleStep.type?(semantic) -> "fluid_scale_step"
      true -> nil
    end
  end
end
