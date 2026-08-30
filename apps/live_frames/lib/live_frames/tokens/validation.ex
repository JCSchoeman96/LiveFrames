defmodule LiveFrames.Tokens.Validation do
  @moduledoc """
  Validates the source-independent TokenSet contract.

  Validation never repairs a TokenSet. It reports structural, reference, and
  requirement failures as deterministic diagnostics.
  """

  alias LiveFrames.Tokens.Diagnostic
  alias LiveFrames.Tokens.Token
  alias LiveFrames.Tokens.TokenSet
  alias LiveFrames.Tokens.ValidationError

  @categories [:color, :spacing, :typography, :button, :layout, :radius, :overlay]
  @statuses [:resolved, :unresolved]
  @diagnostic_severities [:info, :warning, :error, :fatal]
  @diagnostic_categories [
    :source,
    :version,
    :mapping,
    :value,
    :path,
    :reference,
    :required,
    :provenance,
    :serialization
  ]
  @path_pattern ~r/^[a-z][a-z0-9]*(\.[a-z][a-z0-9_]*)*$/

  @spec validate(term(), keyword()) :: :ok | {:error, [Diagnostic.t()]}
  def validate(%TokenSet{} = token_set, opts) when is_list(opts) do
    diagnostics = []
    diagnostics = validate_root(token_set, diagnostics)

    {tokens_by_path, diagnostics} =
      if token_registry?(token_set.tokens) do
        validate_tokens(token_set.tokens, diagnostics)
      else
        {Map.new(),
         add(diagnostics, error("tokens.object.invalid", "tokens must be a map", :path))}
      end

    diagnostics = validate_references(tokens_by_path, diagnostics)
    diagnostics = validate_cycles(tokens_by_path, diagnostics)
    diagnostics = validate_required(tokens_by_path, opts, diagnostics)
    finish(diagnostics)
  end

  def validate(%TokenSet{}, _opts) do
    finish([
      error("tokens.options.invalid", "validation options must be a keyword list", :source)
    ])
  end

  def validate(_token_set, _opts) do
    finish([error("tokens.object.invalid", "expected a TokenSet struct", :source)])
  end

  @spec validate!(term(), keyword()) :: TokenSet.t()
  def validate!(token_set, opts \\ []) do
    case validate(token_set, opts) do
      :ok ->
        token_set

      {:error, diagnostics} ->
        raise ValidationError, diagnostics: diagnostics
    end
  end

  defp validate_root(token_set, diagnostics) do
    diagnostics
    |> validate_version(token_set.token_set_version)
    |> validate_json_object(
      token_set.source_metadata,
      "tokens.source_metadata.invalid",
      "source_metadata must be a JSON object",
      :source
    )
    |> validate_diagnostic_list(token_set.diagnostics)
  end

  defp validate_version(diagnostics, version) do
    cond do
      version == TokenSet.current_token_set_version() ->
        diagnostics

      is_binary(version) ->
        add(
          diagnostics,
          error(
            "tokens.version.unsupported",
            "token_set_version is not supported by this TokenSet contract",
            :version
          )
        )

      true ->
        add(
          diagnostics,
          error("tokens.version.invalid", "token_set_version must be a string", :version)
        )
    end
  end

  defp validate_json_object(diagnostics, value, code, message, category) do
    if json_object?(value),
      do: diagnostics,
      else: add(diagnostics, error(code, message, category))
  end

  defp validate_json_object(diagnostics, value, code, message, category, path) do
    if json_object?(value) do
      diagnostics
    else
      add(diagnostics, error_at(code, message, category, path: path))
    end
  end

  defp validate_diagnostic_list(diagnostics, values) when is_list(values) do
    Enum.reduce(values, diagnostics, fn diagnostic, diagnostics ->
      case diagnostic do
        %Diagnostic{} ->
          diagnostics
          |> validate_diagnostic_field(diagnostic.code, :code)
          |> validate_diagnostic_severity(diagnostic.severity)
          |> validate_diagnostic_category(diagnostic.category)
          |> validate_diagnostic_field(diagnostic.message, :message)
          |> validate_optional_string(diagnostic.path, "tokens.diagnostic.path.invalid")
          |> validate_optional_string(
            diagnostic.source_key,
            "tokens.diagnostic.source_key.invalid"
          )
          |> validate_json_object(
            diagnostic.metadata,
            "tokens.diagnostic.metadata.invalid",
            "diagnostic metadata must be a JSON object",
            :provenance
          )

        _ ->
          add(
            diagnostics,
            error(
              "tokens.diagnostic.invalid",
              "diagnostics must contain TokenSet Diagnostic structs",
              :source
            )
          )
      end
    end)
  end

  defp validate_diagnostic_list(diagnostics, _values) do
    add(diagnostics, error("tokens.diagnostics.invalid", "diagnostics must be a list", :source))
  end

  defp validate_diagnostic_field(diagnostics, value, _field)
       when is_binary(value) and value != "",
       do: diagnostics

  defp validate_diagnostic_field(diagnostics, _value, field) do
    add(
      diagnostics,
      error(
        "tokens.diagnostic.field.invalid",
        "diagnostic #{field} must be a non-empty string",
        :source
      )
    )
  end

  defp validate_diagnostic_severity(diagnostics, severity)
       when severity in @diagnostic_severities,
       do: diagnostics

  defp validate_diagnostic_severity(diagnostics, _severity) do
    add(
      diagnostics,
      error("tokens.diagnostic.severity.invalid", "diagnostic severity is unsupported", :source)
    )
  end

  defp validate_diagnostic_category(diagnostics, category)
       when category in @diagnostic_categories,
       do: diagnostics

  defp validate_diagnostic_category(diagnostics, _category) do
    add(
      diagnostics,
      error("tokens.diagnostic.category.invalid", "diagnostic category is unsupported", :source)
    )
  end

  defp validate_optional_string(diagnostics, nil, _code), do: diagnostics
  defp validate_optional_string(diagnostics, value, _code) when is_binary(value), do: diagnostics

  defp validate_optional_string(diagnostics, _value, code) do
    add(diagnostics, error(code, "optional diagnostic fields must be strings or nil", :source))
  end

  defp validate_tokens(tokens, diagnostics) do
    tokens
    |> Map.to_list()
    |> Enum.sort_by(fn {key, _token} -> sort_key(key) end)
    |> Enum.reduce({%{}, diagnostics}, fn {key, token}, {tokens_by_path, diagnostics} ->
      canonical_key = normalize_key(key)
      diagnostics = validate_token_map_key(diagnostics, key, canonical_key)

      case token do
        %Token{} ->
          diagnostics = validate_token(token, canonical_key, diagnostics)
          path = if is_binary(token.path), do: token.path, else: canonical_key

          if valid_path?(path) and not Map.has_key?(tokens_by_path, path) do
            {Map.put(tokens_by_path, path, token), diagnostics}
          else
            diagnostics =
              if valid_path?(path) do
                add(
                  diagnostics,
                  error_at(
                    "tokens.path.duplicate",
                    "canonical token paths must be unique",
                    :path,
                    path: path
                  )
                )
              else
                diagnostics
              end

            {tokens_by_path, diagnostics}
          end

        _ ->
          diagnostics =
            add(
              diagnostics,
              error_at(
                "tokens.token.invalid",
                "tokens must contain Token structs",
                :path,
                path: if(is_binary(canonical_key), do: canonical_key, else: nil)
              )
            )

          {tokens_by_path, diagnostics}
      end
    end)
  end

  defp validate_token_map_key(diagnostics, key, canonical_key) when is_binary(key) do
    if canonical_key == key do
      diagnostics
    else
      add(
        diagnostics,
        error_at(
          "tokens.path.invalid",
          "token map keys must be canonical string paths",
          :path,
          path: canonical_key
        )
      )
    end
  end

  defp validate_token_map_key(diagnostics, _key, canonical_key) do
    add(
      diagnostics,
      error_at(
        "tokens.path.invalid",
        "token map keys must be canonical string paths",
        :path,
        path: canonical_key
      )
    )
  end

  defp validate_token(token, canonical_key, diagnostics) do
    diagnostics
    |> validate_path(token.path, canonical_key)
    |> validate_category(token.category, canonical_key)
    |> validate_status(token.resolution_status, canonical_key)
    |> validate_token_value(token.value, canonical_key, token.references)
    |> validate_json_value(
      token.resolved_value,
      "tokens.resolved_value.invalid",
      "resolved_value must be JSON-safe",
      canonical_key
    )
    |> validate_json_value(
      token.source_expression,
      "tokens.source_expression.invalid",
      "source_expression must be JSON-safe",
      canonical_key
    )
    |> validate_references_shape(token.references, canonical_key)
    |> validate_json_object(
      token.provenance,
      "tokens.provenance.invalid",
      "token provenance must be a JSON object",
      :provenance,
      canonical_key
    )
    |> validate_json_object(
      token.metadata,
      "tokens.metadata.invalid",
      "token metadata must be a JSON object",
      :provenance,
      canonical_key
    )
  end

  defp validate_path(diagnostics, path, canonical_key) when is_binary(path) do
    diagnostics =
      if valid_path?(path) do
        diagnostics
      else
        add(
          diagnostics,
          error_at("tokens.path.invalid", "token path has an invalid canonical format", :path,
            path: path
          )
        )
      end

    if path == canonical_key do
      diagnostics
    else
      add(
        diagnostics,
        error_at("tokens.path.invalid", "token path must match its token map key", :path,
          path: path
        )
      )
    end
  end

  defp validate_path(diagnostics, _path, canonical_key) do
    add(
      diagnostics,
      error_at("tokens.path.invalid", "token path must be a canonical string", :path,
        path: canonical_key
      )
    )
  end

  defp validate_category(diagnostics, category, _path) when category in @categories,
    do: diagnostics

  defp validate_category(diagnostics, _category, path) do
    add(
      diagnostics,
      error_at("tokens.category.invalid", "token category is unsupported", :path, path: path)
    )
  end

  defp validate_status(diagnostics, status, _path) when status in @statuses,
    do: diagnostics

  defp validate_status(diagnostics, _status, path) do
    add(
      diagnostics,
      error_at("tokens.status.invalid", "token resolution_status is unsupported", :path,
        path: path
      )
    )
  end

  defp validate_token_value(diagnostics, value, path, references) do
    diagnostics =
      validate_json_value(
        diagnostics,
        value,
        "tokens.value.invalid",
        "token value must be JSON-safe",
        path
      )

    case value do
      %{"type" => "reference"} ->
        validate_reference_value(diagnostics, value, path, references)

      %{"type" => "derived"} ->
        validate_derived_value(diagnostics, value, path)

      %{"type" => "responsive"} ->
        diagnostics

      _ ->
        diagnostics
    end
  end

  defp validate_json_value(diagnostics, value, code, message, path) do
    if json_value?(value) do
      diagnostics
    else
      add(diagnostics, error_at(code, message, :value, path: path))
    end
  end

  defp validate_reference_value(diagnostics, value, path, references) do
    reference_path = Map.get(value, "path")

    if is_binary(reference_path) and valid_path?(reference_path) and is_list(references) and
         reference_path in references do
      diagnostics
    else
      add(
        diagnostics,
        error_at(
          "tokens.reference.invalid",
          "reference values must contain a valid semantic path and matching edge",
          :reference,
          path: path
        )
      )
    end
  end

  defp validate_derived_value(diagnostics, value, path) do
    recipe = Map.get(value, "recipe")
    inputs = Map.get(value, "inputs")

    if is_binary(recipe) and recipe != "" and json_object?(inputs) do
      diagnostics
    else
      add(
        diagnostics,
        error_at(
          "tokens.value.derived_invalid",
          "derived values require a recipe and JSON-object inputs",
          :value,
          path: path
        )
      )
    end
  end

  defp validate_references_shape(diagnostics, references, path) when is_list(references) do
    Enum.reduce(references, diagnostics, fn reference, diagnostics ->
      if is_binary(reference) and valid_path?(reference) do
        diagnostics
      else
        add(
          diagnostics,
          error_at(
            "tokens.reference.invalid",
            "references must contain canonical semantic paths",
            :reference,
            path: path
          )
        )
      end
    end)
  end

  defp validate_references_shape(diagnostics, _references, path) do
    add(
      diagnostics,
      error_at(
        "tokens.reference.invalid",
        "references must be a list of canonical paths",
        :reference,
        path: path
      )
    )
  end

  defp validate_references(tokens_by_path, diagnostics) do
    Enum.reduce(tokens_by_path, diagnostics, fn {path, token}, diagnostics ->
      references = if is_list(token.references), do: token.references, else: []

      Enum.reduce(references, diagnostics, fn reference, diagnostics ->
        if Map.has_key?(tokens_by_path, reference) do
          diagnostics
        else
          add(
            diagnostics,
            error_at(
              "tokens.reference.missing",
              "token reference does not resolve to a canonical token",
              :reference,
              path: path,
              metadata: %{"reference" => reference}
            )
          )
        end
      end)
    end)
  end

  defp validate_cycles(tokens_by_path, diagnostics) do
    graph =
      Map.new(tokens_by_path, fn {path, token} ->
        references =
          if is_list(token.references) do
            Enum.filter(token.references, &(is_binary(&1) and valid_path?(&1)))
          else
            []
          end

        {path, references}
      end)

    paths = tokens_by_path |> Map.keys() |> Enum.sort()

    {_visited, diagnostics, _cycles} =
      Enum.reduce(paths, {MapSet.new(), diagnostics, MapSet.new()}, fn path, state ->
        detect_cycles(path, graph, [], state)
      end)

    diagnostics
  end

  defp detect_cycles(path, graph, stack, {visited, diagnostics, cycles}) do
    cond do
      path in stack ->
        cycle = cycle_path(path, stack)
        cycle_key = cycle |> Enum.drop(-1) |> Enum.sort() |> Enum.join("|")

        if MapSet.member?(cycles, cycle_key) do
          {visited, diagnostics, cycles}
        else
          diagnostic =
            error_at(
              "tokens.reference.cycle",
              "token references must not contain cycles",
              :reference,
              path: path,
              metadata: %{"cycle" => cycle}
            )

          {visited, add(diagnostics, diagnostic), MapSet.put(cycles, cycle_key)}
        end

      MapSet.member?(visited, path) ->
        {visited, diagnostics, cycles}

      true ->
        visited = MapSet.put(visited, path)
        stack = stack ++ [path]

        Enum.reduce(Map.get(graph, path, []), {visited, diagnostics, cycles}, fn target, state ->
          if Map.has_key?(graph, target) do
            detect_cycles(target, graph, stack, state)
          else
            state
          end
        end)
    end
  end

  defp cycle_path(path, stack) do
    stack
    |> Enum.drop_while(&(&1 != path))
    |> Kernel.++([path])
  end

  defp validate_required(tokens_by_path, opts, diagnostics) do
    strict? = Keyword.get(opts, :strict, false)
    required_paths = Keyword.get(opts, :required_paths, [])

    cond do
      not is_boolean(strict?) ->
        add(diagnostics, error("tokens.options.invalid", "strict must be a boolean", :required))

      not is_list(required_paths) ->
        add(
          diagnostics,
          error("tokens.required.invalid", "required_paths must be a list", :required)
        )

      strict? ->
        required_paths
        |> Enum.uniq()
        |> Enum.sort_by(&sort_key/1)
        |> Enum.reduce(diagnostics, fn path, diagnostics ->
          case Map.get(tokens_by_path, path) do
            %Token{resolution_status: :resolved} ->
              diagnostics

            %Token{resolution_status: status} ->
              add_required_diagnostic(diagnostics, path, status)

            _ ->
              add_required_diagnostic(diagnostics, path, :missing)
          end
        end)

      true ->
        diagnostics
    end
  end

  defp add_required_diagnostic(diagnostics, path, status) do
    add(
      diagnostics,
      error_at(
        "tokens.required.missing",
        "a required token is missing or unresolved",
        :required,
        path: if(is_binary(path), do: path, else: nil),
        metadata: %{"required_path" => path, "status" => status_label(status)}
      )
    )
  end

  defp finish([]), do: :ok

  defp finish(diagnostics) do
    {:error,
     diagnostics
     |> Enum.reverse()
     |> Enum.sort_by(fn diagnostic ->
       {diagnostic.code || "", diagnostic.path || "", diagnostic.source_key || "",
        diagnostic.message || ""}
     end)}
  end

  defp add(diagnostics, diagnostic), do: [diagnostic | diagnostics]

  defp error(code, message, category),
    do: Diagnostic.new(code: code, severity: :error, category: category, message: message)

  defp error_at(code, message, category, attrs) do
    Diagnostic.new([code: code, severity: :error, category: category, message: message] ++ attrs)
  end

  defp token_registry?(value), do: is_map(value) and not is_struct(value)

  defp normalize_key(key) when is_binary(key), do: key
  defp normalize_key(key) when is_atom(key), do: Atom.to_string(key)
  defp normalize_key(_key), do: nil

  defp sort_key(key) when is_binary(key), do: key
  defp sort_key(key) when is_atom(key), do: Atom.to_string(key)
  defp sort_key(key), do: inspect(key)

  defp valid_path?(path) when is_binary(path), do: Regex.match?(@path_pattern, path)
  defp valid_path?(_path), do: false

  defp status_label(status) when is_atom(status), do: Atom.to_string(status)
  defp status_label(status) when is_binary(status), do: status
  defp status_label(status), do: inspect(status)

  defp json_object?(value) when is_map(value) and not is_struct(value) do
    case json_keys(Map.keys(value)) do
      {:ok, keys} ->
        length(keys) == length(Enum.uniq(keys)) and Enum.all?(Map.values(value), &json_value?/1)

      :error ->
        false
    end
  end

  defp json_object?(_value), do: false

  defp json_keys(keys) do
    Enum.reduce_while(keys, [], fn key, acc ->
      case json_key(key) do
        {:ok, key} -> {:cont, [key | acc]}
        :error -> {:halt, :error}
      end
    end)
    |> case do
      :error -> :error
      keys -> {:ok, keys}
    end
  end

  defp json_key(key) when is_binary(key), do: {:ok, key}
  defp json_key(key) when is_atom(key), do: {:ok, Atom.to_string(key)}
  defp json_key(_key), do: :error

  defp json_value?(nil), do: true
  defp json_value?(value) when is_binary(value), do: true
  defp json_value?(value) when is_boolean(value), do: true
  defp json_value?(value) when is_integer(value), do: true
  defp json_value?(value) when is_float(value), do: true
  defp json_value?(value) when is_list(value), do: Enum.all?(value, &json_value?/1)
  defp json_value?(value) when is_map(value) and not is_struct(value), do: json_object?(value)
  defp json_value?(_value), do: false
end
