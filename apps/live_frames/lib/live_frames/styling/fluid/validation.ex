defmodule LiveFrames.Styling.Fluid.Validation do
  @moduledoc """
  Fluid semantic and reference authority over an indexed TokenSet registry.

  Validation is pure and compile-time. Intrinsic shape rules stay owned by the
  Fluid semantic modules; this module dispatches to them, requires each
  Fluid token's declared `references` to equal its canonical semantic edge,
  and checks the recognized semantic type of an indexed target.

  Missing-reference and reference-cycle diagnostics remain owned by
  `LiveFrames.Tokens.Validation`.
  """

  alias LiveFrames.Styling.Fluid.Domain
  alias LiveFrames.Styling.Fluid.Scale
  alias LiveFrames.Styling.Fluid.ScaleStep
  alias LiveFrames.Styling.Fluid.Value
  alias LiveFrames.Tokens.Diagnostic
  alias LiveFrames.Tokens.Token

  @semantic_modules [
    {"fluid_domain", Domain},
    {"fluid_value", Value},
    {"fluid_scale", Scale},
    {"fluid_scale_step", ScaleStep}
  ]

  @fluid_prefix "fluid_"

  @spec validate_registry(%{optional(String.t()) => Token.t()}) :: [Diagnostic.t()]
  def validate_registry(tokens_by_path) when is_map(tokens_by_path) do
    tokens_by_path
    |> Enum.sort_by(fn {path, _token} -> path end)
    |> Enum.flat_map(fn {path, token} -> validate_token(path, token, tokens_by_path) end)
  end

  defp validate_token(
         path,
         %Token{resolved_value: %{"type" => type} = semantic} = token,
         registry
       )
       when is_binary(type) do
    if String.starts_with?(type, @fluid_prefix) do
      validate_semantic(path, type, semantic, token.references, registry)
    else
      []
    end
  end

  defp validate_token(_path, _token, _registry), do: []

  # Unsupported fluid-prefixed tags fail closed here: they never fall through
  # to ordinary semantic maps.
  defp validate_semantic(path, type, semantic, references, registry) do
    case List.keyfind(@semantic_modules, type, 0) do
      {_tag, module} ->
        case module.validate(semantic) do
          :ok -> validate_edges(path, type, semantic, references, registry)
          {:error, _reason} -> [semantic_invalid(path)]
        end

      nil ->
        [semantic_invalid(path)]
    end
  end

  defp validate_edges(path, type, semantic, references, registry) do
    {target_type, expected} = edge_requirement(type, semantic)

    if references == expected do
      check_declared_target(path, target_type, expected, registry)
    else
      [reference_invalid(path, expected)]
    end
  end

  defp check_declared_target(_path, nil, _expected, _registry), do: []

  defp check_declared_target(path, target_type, [target_ref], registry),
    do: check_target_type(path, target_type, target_ref, registry)

  defp edge_requirement("fluid_domain", _semantic), do: {nil, []}

  defp edge_requirement("fluid_value", semantic),
    do: {"fluid_domain", [semantic["domain_ref"]]}

  defp edge_requirement("fluid_scale", semantic),
    do: {"fluid_domain", [semantic["domain_ref"]]}

  defp edge_requirement("fluid_scale_step", semantic),
    do: {"fluid_scale", [semantic["scale_ref"]]}

  # Indexed lookup only. A missing target is reported by TokenSet reference
  # authority, and an unresolved target without semantic evidence is left to
  # resolution rather than classified as a wrong type.
  defp check_target_type(path, expected_type, target_ref, registry) do
    case Map.fetch(registry, target_ref) do
      :error ->
        []

      {:ok, %Token{resolved_value: nil}} ->
        []

      {:ok, %Token{resolved_value: resolved_value}} ->
        actual_type = semantic_type_label(resolved_value)

        if actual_type == expected_type do
          []
        else
          [type_mismatch(path, expected_type, actual_type, target_ref)]
        end
    end
  end

  defp semantic_type_label(resolved_value) do
    case Enum.find(@semantic_modules, fn {_tag, module} -> module.type?(resolved_value) end) do
      {tag, _module} ->
        tag

      nil ->
        if fluid_prefixed?(resolved_value), do: "unrecognized_fluid", else: "non_fluid"
    end
  end

  defp fluid_prefixed?(%{"type" => type}) when is_binary(type),
    do: String.starts_with?(type, @fluid_prefix)

  defp fluid_prefixed?(_resolved_value), do: false

  defp semantic_invalid(path) do
    Diagnostic.new(
      code: "fluid.semantic.invalid",
      severity: :error,
      category: :value,
      message: "fluid semantic value is malformed or unsupported",
      path: path
    )
  end

  defp reference_invalid(path, expected) do
    Diagnostic.new(
      code: "fluid.reference.invalid",
      severity: :error,
      category: :reference,
      message: "fluid references must exactly match the canonical semantic edge",
      path: path,
      metadata: %{"expected_references" => expected}
    )
  end

  defp type_mismatch(path, expected_type, actual_type, reference) do
    Diagnostic.new(
      code: "fluid.reference.type_mismatch",
      severity: :error,
      category: :reference,
      message: "fluid reference target has the wrong semantic type",
      path: path,
      metadata: %{
        "expected_type" => expected_type,
        "actual_type" => actual_type,
        "reference" => reference
      }
    )
  end
end
