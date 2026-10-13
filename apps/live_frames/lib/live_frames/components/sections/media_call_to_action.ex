defmodule LiveFrames.Components.Sections.MediaCallToAction do
  use Phoenix.Component

  attr(:class, :string)
  attr(:eyebrow, :string)
  attr(:heading, :string, required: true)
  attr(:heading_level, :integer, default: 2, values: 1..6)
  attr(:image_1_alt, :string, required: true)
  attr(:image_1_src, :string, required: true)
  attr(:image_2_alt, :string, required: true)
  attr(:image_2_src, :string, required: true)
  attr(:image_3_alt, :string, required: true)
  attr(:image_3_src, :string, required: true)
  attr(:rest, :global)
  slot(:body)
  slot(:primary_action, required: true)

  def media_call_to_action(assigns) do
    lf_validate_first_wave_slots!(assigns)

    ~H"""
    <section class={["lf-section-media-call-to-action", "lf-section-media-call-to-action__n-000001", Map.get(assigns, :class)]} {lf_optional_global_attrs(Map.get(assigns, :rest))}><div class={"lf-section-media-call-to-action__n-000001-000001"}><div class={"lf-section-media-call-to-action__n-000001-000001-000001"}><div class={"lf-section-media-call-to-action__n-000001-000001-000001-000001"}><div class={"lf-section-media-call-to-action__n-000001-000001-000001-000001-000001"}><figure class={"lf-section-media-call-to-action__n-000001-000001-000001-000001-000001-000001"}><%= case @image_1_alt do %>
      <% lf_alt when lf_alt in [nil, ""] -> %>
        <% raise ArgumentError, "image alt is required when source is present" %>
      <% lf_alt -> %>
        <img src={@image_1_src} alt={lf_alt} />
    <% end %></figure></div>
    <div class={"lf-section-media-call-to-action__n-000001-000001-000001-000001-000002"}><figure class={"lf-section-media-call-to-action__n-000001-000001-000001-000001-000002-000001"}><%= case @image_2_alt do %>
      <% lf_alt when lf_alt in [nil, ""] -> %>
        <% raise ArgumentError, "image alt is required when source is present" %>
      <% lf_alt -> %>
        <img src={@image_2_src} alt={lf_alt} />
    <% end %></figure></div>
    <div class={"lf-section-media-call-to-action__n-000001-000001-000001-000001-000003"}><figure class={"lf-section-media-call-to-action__n-000001-000001-000001-000001-000003-000001"}><%= case @image_3_alt do %>
      <% lf_alt when lf_alt in [nil, ""] -> %>
        <% raise ArgumentError, "image alt is required when source is present" %>
      <% lf_alt -> %>
        <img src={@image_3_src} alt={lf_alt} />
    <% end %></figure></div></div></div>
    <div class={"lf-section-media-call-to-action__n-000001-000001-000002"}><%= case @heading_level do %>
        <% 1 -> %><h1 class={"lf-section-media-call-to-action__n-000001-000001-000002-000001"}>{@heading}</h1>
        <% 2 -> %><h2 class={"lf-section-media-call-to-action__n-000001-000001-000002-000001"}>{@heading}</h2>
        <% 3 -> %><h3 class={"lf-section-media-call-to-action__n-000001-000001-000002-000001"}>{@heading}</h3>
        <% 4 -> %><h4 class={"lf-section-media-call-to-action__n-000001-000001-000002-000001"}>{@heading}</h4>
        <% 5 -> %><h5 class={"lf-section-media-call-to-action__n-000001-000001-000002-000001"}>{@heading}</h5>
        <% 6 -> %><h6 class={"lf-section-media-call-to-action__n-000001-000001-000002-000001"}>{@heading}</h6>
    <% end %>
    <p class={"lf-section-media-call-to-action__n-000001-000001-000002-000002"}>{Map.get(assigns, :eyebrow)}</p>
    <%= render_slot(@body) %>
    <span class={"lf-section-media-call-to-action__n-000001-000001-000002-000004"}><%= render_slot(@primary_action) %></span></div></div></section>
    """
  end

  defp lf_optional_global_attrs(value) do
    case value do
      nil -> %{}
      attrs when is_map(attrs) -> attrs
      attrs when is_list(attrs) -> Enum.into(attrs, %{})
      _ -> raise ArgumentError, "root global attrs must be a map or keyword list"
    end
  end

  defp lf_validate_first_wave_slots!(assigns) do
    case Map.get(assigns, :body) do
      nil ->
        :ok

      [] ->
        :ok

      [_] ->
        :ok

      _ ->
        raise ArgumentError, "slot body allows at most one entry"
    end

    case Map.get(assigns, :primary_action) do
      nil ->
        raise ArgumentError, "required slot primary_action is missing"

      [] ->
        raise ArgumentError, "required slot primary_action is missing"

      [_] ->
        :ok

      _ ->
        raise ArgumentError, "slot primary_action allows at most one entry"
    end

    :ok
  end
end
