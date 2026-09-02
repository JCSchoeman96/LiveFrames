defmodule LiveFrames.Fidelity.CSSDeclaration do
  @moduledoc false

  @origins [:ir, :source_resolver]
  @safe_property ~r/^[a-z][a-z0-9]*(?:-[a-z0-9]+)*$/
  @safe_custom_property ~r/^--[a-z][a-z0-9]*(?:-[a-z0-9]+)*$/
  @unsafe_value ~r/[{};\\]/
  @unsafe_external_url ~r/url\s*\(\s*(?:["']\s*|\/\*.*?\*\/\s*)*(?:https?:|\/\/|javascript:)/is

  @type origin :: :ir | :source_resolver
  @type selector :: nil | :hover | :focus_visible
  @type state :: :received | :validated | :accepted | :serialized | :rejected | :unresolved

  @type t :: %__MODULE__{
          property: String.t() | nil,
          value: String.t() | nil,
          path: String.t() | nil,
          selector: selector(),
          origin: origin() | nil,
          state: state()
        }

  defstruct property: nil,
            value: nil,
            path: nil,
            selector: nil,
            origin: nil,
            state: :received

  @spec normalize(map(), origin()) ::
          {:ok, t()} | {:unresolved, t()} | {:rejected, t(), atom()}
  def normalize(raw, origin) when origin in @origins do
    received = %__MODULE__{origin: origin, state: :received}

    case validate(raw, received) do
      {:ok, validated} ->
        case accept(validated) do
          {:ok, accepted} ->
            if is_nil(accepted.value) do
              {:unresolved, %{accepted | state: :unresolved}}
            else
              {:ok, accepted}
            end

          {:error, reason} ->
            reject(received, reason)
        end

      {:error, reason} ->
        reject(received, reason)
    end
  end

  def normalize(_raw, origin),
    do: {:rejected, %__MODULE__{origin: origin, state: :rejected}, :invalid_declaration_shape}

  @spec serialize(t()) :: {:ok, t(), String.t()} | {:error, :not_accepted}
  def serialize(%__MODULE__{state: :accepted, property: property, value: value} = declaration)
      when is_binary(property) and is_binary(value) do
    if property != "custom-css" and safe_property?(property) and safe_value?(value) and
         declaration.selector in [nil, :hover, :focus_visible] do
      {:ok, %{declaration | state: :serialized}, "  " <> property <> ": " <> value <> ";"}
    else
      {:error, :not_accepted}
    end
  end

  def serialize(_declaration), do: {:error, :not_accepted}

  @spec selector_suffix(selector()) :: String.t()
  def selector_suffix(nil), do: ""
  def selector_suffix(:hover), do: ":hover"
  def selector_suffix(:focus_visible), do: ":focus-visible"

  @spec selector_sort_key(selector()) :: non_neg_integer()
  def selector_sort_key(:focus_visible), do: 0
  def selector_sort_key(:hover), do: 1

  @spec safe_property?(term()) :: boolean()
  def safe_property?(property) when is_binary(property),
    do: Regex.match?(@safe_property, property) or Regex.match?(@safe_custom_property, property)

  def safe_property?(_property), do: false

  @spec safe_value?(term()) :: boolean()
  def safe_value?(value) when is_binary(value),
    do: not Regex.match?(@unsafe_value, value) and not unsafe_external_url?(value)

  def safe_value?(_value), do: false

  @spec unsafe_external_url?(term()) :: boolean()
  def unsafe_external_url?(value) when is_binary(value),
    do: Regex.match?(@unsafe_external_url, value)

  def unsafe_external_url?(_value), do: false

  defp validate(raw, received) do
    with {:ok, fields} <- declaration_fields(raw),
         {:ok, property} <- validate_property(fields.property),
         :ok <- validate_not_custom_css(property),
         {:ok, path} <- validate_path(fields.path),
         {:ok, selector} <- validate_selector(fields.selector),
         {:ok, value} <- validate_value(fields.value) do
      {:ok,
       %{
         received
         | property: property,
           value: value,
           path: path,
           selector: selector,
           state: :validated
       }}
    end
  end

  defp declaration_fields(raw) when is_map(raw) and not is_struct(raw) do
    with {:ok, property} <- required_field(raw, :property),
         {:ok, value} <- required_field(raw, :value),
         {:ok, path} <- optional_field(raw, :path),
         {:ok, selector} <- optional_field(raw, :selector) do
      {:ok, %{property: property, value: value, path: path, selector: selector}}
    end
  end

  defp declaration_fields(_raw), do: {:error, :invalid_declaration_shape}

  defp required_field(raw, key) do
    case field(raw, key) do
      {:ok, value} -> {:ok, value}
      :missing -> {:error, :invalid_declaration_shape}
      :conflict -> {:error, :invalid_declaration_shape}
    end
  end

  defp optional_field(raw, key) do
    case field(raw, key) do
      {:ok, value} -> {:ok, value}
      :missing -> {:ok, nil}
      :conflict -> {:error, :invalid_declaration_shape}
    end
  end

  defp field(raw, key) do
    string_key = Atom.to_string(key)

    case {Map.fetch(raw, key), Map.fetch(raw, string_key)} do
      {{:ok, value}, :error} -> {:ok, value}
      {:error, {:ok, value}} -> {:ok, value}
      {{:ok, value}, {:ok, value}} -> {:ok, value}
      {{:ok, _value}, {:ok, _other_value}} -> :conflict
      {:error, :error} -> :missing
    end
  end

  defp validate_property(property) when is_binary(property) do
    cond do
      safe_property?(property) -> {:ok, property}
      true -> {:error, :invalid_css_property}
    end
  end

  defp validate_property(_property), do: {:error, :invalid_css_property}

  defp validate_path(nil), do: {:ok, nil}
  defp validate_path(path) when is_binary(path), do: {:ok, path}
  defp validate_path(_path), do: {:error, :invalid_declaration_shape}

  defp validate_selector(nil), do: {:ok, nil}
  defp validate_selector("&:hover"), do: {:ok, :hover}
  defp validate_selector("&:focus-visible"), do: {:ok, :focus_visible}
  defp validate_selector(_selector), do: {:error, :unsupported_selector}

  defp validate_value(nil), do: {:ok, nil}

  defp validate_value(value) when is_binary(value) do
    if safe_value?(value),
      do: {:ok, value},
      else: {:error, :unsafe_css_value}
  end

  defp validate_value(_value), do: {:error, :invalid_css_value}

  defp validate_not_custom_css("custom-css"), do: {:error, :custom_css_forbidden}
  defp validate_not_custom_css(_property), do: :ok

  defp accept(%__MODULE__{state: :validated, property: "custom-css"}),
    do: {:error, :custom_css_forbidden}

  defp accept(%__MODULE__{state: :validated} = declaration),
    do: {:ok, %{declaration | state: :accepted}}

  defp accept(_declaration), do: {:error, :not_validated}

  defp reject(declaration, reason), do: {:rejected, %{declaration | state: :rejected}, reason}
end
