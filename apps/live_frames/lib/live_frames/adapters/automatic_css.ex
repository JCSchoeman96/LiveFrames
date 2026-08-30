defmodule LiveFrames.Adapters.AutomaticCSS do
  @moduledoc """
  Public boundary for normalizing Automatic.css settings into LiveFrames
  TokenSets.

  The adapter is a compile-time/data-conversion dependency only. It is not
  required by consumers of a serialized TokenSet.
  """

  alias LiveFrames.Adapters.AutomaticCSS.Loader
  alias LiveFrames.Adapters.AutomaticCSS.Normalizer
  alias LiveFrames.Tokens
  alias LiveFrames.Tokens.Diagnostic
  alias LiveFrames.Tokens.TokenSet

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

  @spec from_file(term(), keyword()) ::
          {:ok, TokenSet.t(), [Diagnostic.t()]} | {:error, [Diagnostic.t()]}
  def from_file(path, opts \\ []) do
    with {:ok, settings, source_metadata} <- Loader.from_file(path, opts) do
      normalize_recognized(settings, source_metadata, opts)
    end
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

  @spec profiles() :: map()
  def profiles, do: @profiles

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
    with {:ok, required_paths} <- required_paths_for(opts),
         {tokens, diagnostics} <- Normalizer.normalize(settings, source_metadata, opts) do
      token_set = %TokenSet{
        source_metadata: source_metadata,
        tokens: tokens,
        diagnostics: diagnostics
      }

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
end
