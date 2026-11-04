defmodule LiveFrames.Adapters.AutomaticCSS do
  @moduledoc """
  Public boundary for normalizing Automatic.css settings into LiveFrames
  TokenSets.

  The adapter is a compile-time/data-conversion dependency only. It is not
  required by consumers of a serialized TokenSet.
  """

  alias LiveFrames.Adapters.AutomaticCSS.Loader
  alias LiveFrames.Adapters.AutomaticCSS.Normalizer
  alias LiveFrames.Adapters.AutomaticCSS.StructuralVariables
  alias LiveFrames.Fidelity.CSSDeclaration
  alias LiveFrames.Styles.StructuralVariableAuthority
  alias LiveFrames.Tokens
  alias LiveFrames.Tokens.Diagnostic
  alias LiveFrames.Tokens.Token
  alias LiveFrames.Tokens.TokenSet
  alias LiveFrames.Tokens.VariableAuthority

  @hero_foundation_required_paths [
    "color.primary",
    "color.primary.hover",
    "color.primary.light",
    "color.primary.ultra_dark",
    "color.neutral",
    "color.neutral.ultra_dark",
    "color.background.ultra_dark",
    "color.background.ultra_dark.text",
    "color.background.ultra_dark.heading",
    "color.text.light",
    "color.white",
    "spacing.base.min",
    "spacing.base.max",
    "spacing.content_gap",
    "spacing.gutter.min",
    "spacing.gutter.max",
    "typography.body.base_size",
    "typography.body.line_height",
    "typography.heading.base_size",
    "typography.heading.line_height",
    "typography.heading.font_weight",
    "button.primary.background",
    "button.primary.background_hover",
    "button.primary.text",
    "button.primary.border",
    "button.primary.border_width",
    "button.primary.border_style",
    "button.primary.focus",
    "button.primary.radius",
    "button.primary.padding_inline",
    "button.primary.padding_block",
    "button.primary.min_width",
    "button.primary.font_size",
    "button.primary.font_weight",
    "button.primary.line_height",
    "button.primary.outline.background",
    "button.primary.outline.background_hover",
    "button.primary.outline.border",
    "button.primary.outline.border_hover",
    "button.primary.outline.focus",
    "button.primary.outline.text",
    "button.primary.outline.text_hover",
    "layout.viewport.min",
    "layout.viewport.max"
  ]

  @profiles %{hero_foundation: @hero_foundation_required_paths}
  @trusted_identity_options [:source_version, :source_version_status, :export_version]
  @bg_feature_option "option-contextual-color-variables"
  @bg_source_key "bg-ultra-light"
  @bg_token_path "color.background.ultra_light"
  @bg_variable "--bg-ultra-light"
  @bg_authority %{
    "variable" => @bg_variable,
    "kind" => "source_output_alias",
    "authority_id" => "automatic-css-4.0.1:contextual-background:bg-ultra-light",
    "source_key" => @bg_source_key,
    "source_version" => "4.0.1"
  }

  @spec from_file(term(), keyword()) ::
          {:ok, TokenSet.t(), [Diagnostic.t()]} | {:error, [Diagnostic.t()]}
  def from_file(path, opts \\ []) do
    with {:ok, settings, source_metadata} <- Loader.from_file(path, opts) do
      normalize_recognized(settings, source_metadata, opts)
    end
  end

  @spec from_reference_file(term(), keyword()) ::
          {:ok, TokenSet.t(), [Diagnostic.t()]} | {:error, [Diagnostic.t()]}
  def from_reference_file(path, opts \\ [])

  def from_reference_file(path, opts) when is_binary(path) and is_list(opts) do
    if Keyword.keyword?(opts) do
      with {:ok, settings, source_metadata} <- Loader.from_reference_file(path) do
        normalization_opts = Keyword.drop(opts, @trusted_identity_options)

        # This post-normalizer step is only attached after the Loader verifies
        # the fixed reference bytes. Caller options and decoded maps cannot set it.
        normalize_recognized(
          settings,
          source_metadata,
          normalization_opts,
          &add_trusted_bg_alias(&1, settings)
        )
      end
    else
      trusted_reference_input_error("Trusted Automatic.css options must be a keyword list")
    end
  end

  def from_reference_file(_path, _opts) do
    trusted_reference_input_error(
      "Trusted Automatic.css path must be binary and options a keyword list"
    )
  end

  @spec from_json(term(), keyword()) ::
          {:ok, TokenSet.t(), [Diagnostic.t()]} | {:error, [Diagnostic.t()]}
  def from_json(json, opts \\ []) do
    with {:ok, settings, source_metadata} <- Loader.from_json(json, opts) do
      normalize_recognized(settings, source_metadata, opts)
    end
  end

  @spec normalize(term(), keyword()) ::
          {:ok, TokenSet.t(), [Diagnostic.t()]} | {:error, [Diagnostic.t()]}
  def normalize(settings, opts \\ []) do
    with {:ok, settings, source_metadata} <- Loader.recognize(settings, opts) do
      normalize_recognized(settings, source_metadata, opts)
    end
  end

  # This predicate only reads the feature option; verified ingestion remains
  # the only path that can add the BG alias.
  @doc false
  @spec contextual_bg_feature_enabled?(term()) :: boolean()
  def contextual_bg_feature_enabled?(settings) when is_map(settings) do
    Map.get(settings, @bg_feature_option) == "on"
  end

  def contextual_bg_feature_enabled?(_settings), do: false

  @spec profiles() :: map()
  def profiles, do: @profiles

  @spec structural_variable_authority(String.t(), keyword()) ::
          {:ok, StructuralVariableAuthority.t()} | {:error, :unsupported_source_version}
  def structural_variable_authority(source_version, opts \\ []) do
    StructuralVariables.authority(source_version, opts)
  end

  @spec required_paths(atom()) :: [String.t()] | {:error, [Diagnostic.t()]}
  def required_paths(profile) do
    case Map.fetch(@profiles, profile) do
      {:ok, paths} ->
        paths

      :error ->
        {:error,
         [
           Diagnostic.new(
             code: "tokens.profile.unsupported",
             severity: :error,
             category: :required,
             message: "required-token profile is not supported",
             metadata: %{"profile" => inspect(profile)}
           )
         ]}
    end
  end

  defp normalize_recognized(settings, source_metadata, opts) do
    normalize_recognized(settings, source_metadata, opts, &Function.identity/1)
  end

  defp normalize_recognized(settings, source_metadata, opts, post_normalizer) do
    with {:ok, required_paths} <- required_paths_for(opts),
         {tokens, diagnostics} <- Normalizer.normalize(settings, source_metadata, opts) do
      token_set = %TokenSet{
        source_metadata: source_metadata,
        tokens: tokens,
        diagnostics: diagnostics
      }

      token_set = post_normalizer.(token_set)

      validation_opts =
        opts
        |> Keyword.put(:required_paths, required_paths)
        |> Keyword.put_new(:strict, false)

      case Tokens.validate(token_set, validation_opts) do
        :ok ->
          if Enum.any?(diagnostics, &(&1.severity in [:error, :fatal])) do
            {:error, diagnostics}
          else
            {:ok, token_set, diagnostics}
          end

        {:error, validation_diagnostics} ->
          {:error, sort_diagnostics(diagnostics ++ validation_diagnostics)}
      end
    else
      {:error, diagnostics} -> {:error, diagnostics}
    end
  end

  defp add_trusted_bg_alias(%TokenSet{} = token_set, settings) when is_map(settings) do
    with true <- contextual_bg_feature_enabled?(settings),
         true <- Map.has_key?(settings, @bg_source_key),
         {:ok, %Token{} = token} <- Map.fetch(token_set.tokens, @bg_token_path),
         true <- valid_bg_source_token?(token) do
      case add_bg_authority(token_set, token) do
        {:ok, candidate_set} -> verify_bg_direct_owner(token_set, candidate_set)
        :error -> token_set
      end
    else
      _ -> token_set
    end
  end

  defp add_trusted_bg_alias(token_set, _settings), do: token_set

  defp valid_bg_source_token?(%Token{} = token) do
    token.path == @bg_token_path and
      token.resolution_status == :resolved and
      token.value == %{"type" => "reference", "path" => "color.neutral.ultra_light"} and
      token.references == ["color.neutral.ultra_light"] and
      token.metadata["source_key"] == @bg_source_key and
      token.provenance["source_keys"] == [@bg_source_key]
  end

  defp add_bg_authority(%TokenSet{} = token_set, %Token{} = token) do
    authorities = Map.get(token.metadata, "variable_authorities", [])

    if is_list(authorities) and
         not Enum.any?(authorities, &(&1["variable"] == @bg_variable)) do
      metadata =
        Map.put(
          token.metadata,
          "variable_authorities",
          sort_authorities([@bg_authority | authorities])
        )

      token = %{token | metadata: metadata}
      {:ok, %{token_set | tokens: Map.put(token_set.tokens, @bg_token_path, token)}}
    else
      :error
    end
  end

  defp sort_authorities(authorities) do
    Enum.sort_by(authorities, fn authority ->
      {authority["variable"], authority["kind"], authority["authority_id"],
       authority["source_key"] || ""}
    end)
  end

  defp verify_bg_direct_owner(%TokenSet{} = original_set, %TokenSet{} = candidate_set) do
    with {:ok, index} <- VariableAuthority.build(candidate_set),
         {:ok, candidate} <- VariableAuthority.resolve_direct_owner(index, @bg_variable),
         true <- candidate.token_path == @bg_token_path,
         true <- direct_owner_authorities(candidate.authorities) == [@bg_authority],
         {:ok, %{token_path: @bg_token_path}, terminal} <-
           VariableAuthority.resolve_direct_owner_terminal(index, @bg_variable),
         true <- is_binary(terminal) and CSSDeclaration.safe_value?(terminal) do
      candidate_set
    else
      _ -> original_set
    end
  end

  defp direct_owner_authorities(authorities) do
    Enum.filter(authorities, fn
      %{"kind" => kind} -> kind in ["source_output_alias", "explicit_project_contract"]
      _ -> false
    end)
  end

  defp required_paths_for(opts) do
    case Keyword.get(opts, :profile) do
      nil ->
        {:ok, Keyword.get(opts, :required_paths, [])}

      profile ->
        case required_paths(profile) do
          paths when is_list(paths) -> explicit_required_paths(opts, profile, paths)
          {:error, diagnostics} -> {:error, diagnostics}
        end
    end
  end

  defp explicit_required_paths(opts, profile, profile_paths) do
    case Keyword.fetch(opts, :required_paths) do
      :error ->
        {:ok, profile_paths}

      {:ok, required_paths} when is_list(required_paths) ->
        if same_required_paths?(required_paths, profile_paths) do
          {:ok, profile_paths}
        else
          {:error, [required_paths_conflict(profile, required_paths, profile_paths)]}
        end

      {:ok, required_paths} ->
        {:error, [required_paths_conflict(profile, required_paths, profile_paths)]}
    end
  end

  defp same_required_paths?(left, right) do
    Enum.all?(left, &is_binary/1) and Enum.all?(right, &is_binary/1) and
      Enum.sort(Enum.uniq(left)) == Enum.sort(Enum.uniq(right))
  end

  defp required_paths_conflict(profile, requested_paths, profile_paths) do
    Diagnostic.new(
      code: "tokens.required.conflict",
      severity: :error,
      category: :required,
      message: "explicit required_paths cannot override a named required-token profile",
      metadata: %{
        "profile" => inspect(profile),
        "profile_paths" => profile_paths,
        "requested_paths" => inspect(requested_paths)
      }
    )
  end

  defp sort_diagnostics(diagnostics) do
    Enum.sort_by(diagnostics, fn diagnostic ->
      {diagnostic.code || "", diagnostic.path || "", diagnostic.source_key || "",
       diagnostic.message || ""}
    end)
  end

  defp trusted_reference_input_error(message) do
    {:error,
     [
       Diagnostic.new(
         code: "acss.source.invalid",
         severity: :error,
         category: :source,
         message: message
       )
     ]}
  end
end
