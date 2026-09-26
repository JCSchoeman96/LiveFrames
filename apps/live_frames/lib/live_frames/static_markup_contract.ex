defmodule LiveFrames.StaticMarkupContract do
  @moduledoc """
  Fixed native tags and attributes that LiveFrames can emit in static markup.

  This contract is shared by source adapters and Fidelity. It is an allowlist,
  not a general HTML sanitizer.
  """

  @native_tags ~w(
    a
    button
    details
    div
    figure
    h1 h2 h3 h4 h5 h6
    li
    nav
    ol
    p
    picture
    section
    span
    summary
    ul
  )

  @valid_attribute_name ~r/\A[a-z][a-z0-9]*(?:-[a-z0-9]+)*\z/
  @unsafe_control_characters ~r/[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]/
  @button_types ["button", "submit", "reset"]
  @runtime_data_attributes MapSet.new([
                             "data-back-button",
                             "data-icon-list",
                             "data-should-animate",
                             "data-slide-navigation"
                           ])

  @spec native_tag?(term()) :: boolean()
  def native_tag?(tag) when is_binary(tag), do: tag in @native_tags
  def native_tag?(_tag), do: false

  @spec safe_attribute_name?(term()) :: boolean()
  def safe_attribute_name?(name), do: safe_attribute_name?(name, nil)

  @spec safe_attribute_name?(term(), term()) :: boolean()
  def safe_attribute_name?("role", _native_tag), do: true
  def safe_attribute_name?("tabindex", _native_tag), do: true
  def safe_attribute_name?("type", "button"), do: true
  def safe_attribute_name?("name", "details"), do: true

  def safe_attribute_name?(name, _native_tag) when is_binary(name) do
    cond do
      not Regex.match?(@valid_attribute_name, name) ->
        false

      String.starts_with?(name, "aria-") ->
        true

      String.starts_with?(name, "data-") ->
        not String.starts_with?(name, "data-lf-") and
          not MapSet.member?(@runtime_data_attributes, name)

      true ->
        false
    end
  end

  def safe_attribute_name?(_name, _native_tag), do: false

  @spec safe_attribute?(term(), term()) :: boolean()
  def safe_attribute?(name, value), do: safe_attribute?(name, value, nil)

  @spec safe_attribute?(term(), term(), term()) :: boolean()
  def safe_attribute?(name, value, native_tag) do
    safe_attribute_name?(name, native_tag) and is_binary(value) and String.valid?(value) and
      not Regex.match?(@unsafe_control_characters, value) and
      (name != "tabindex" or value == "-1") and
      (name != "type" or value in @button_types)
  end
end
