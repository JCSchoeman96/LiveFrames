defmodule LiveFrames.Components.Sections.Hero do
  @moduledoc false

  use Phoenix.Component

  attr(:heading, :string, required: true)
  attr(:heading_level, :integer, default: 2, values: 1..6)
  attr(:lede, :string, default: nil)
  attr(:image_src, :string, default: nil)
  attr(:image_alt, :string, default: nil)
  attr(:id, :string, default: nil)
  attr(:class, :string, default: nil)
  attr(:rest, :global)

  slot(:primary_action)
  slot(:secondary_action)

  def hero(assigns) do
    validate_contract!(assigns)

    ~H"""
    <section id={@id} class={["lf-hero", @class]} {@rest}>
      <div class="lf-hero__content">
        <%= case @heading_level do %>
          <% 1 -> %>
            <h1 class="lf-hero__heading"><%= @heading %></h1>
          <% 2 -> %>
            <h2 class="lf-hero__heading"><%= @heading %></h2>
          <% 3 -> %>
            <h3 class="lf-hero__heading"><%= @heading %></h3>
          <% 4 -> %>
            <h4 class="lf-hero__heading"><%= @heading %></h4>
          <% 5 -> %>
            <h5 class="lf-hero__heading"><%= @heading %></h5>
          <% 6 -> %>
            <h6 class="lf-hero__heading"><%= @heading %></h6>
        <% end %>
        <%= if @lede do %>
          <p class="lf-hero__lede"><%= @lede %></p>
        <% end %>
        <%= if render_actions?(@primary_action, @secondary_action) do %>
          <div class="lf-hero__actions">
            <%= for entry <- @primary_action do %>
              <div class="lf-hero__action lf-hero__action--primary">
                {render_slot(entry)}
              </div>
            <% end %>
            <%= for entry <- @secondary_action do %>
              <div class="lf-hero__action lf-hero__action--secondary">
                {render_slot(entry)}
              </div>
            <% end %>
          </div>
        <% end %>
      </div>
      <%= if @image_src do %>
        <div class="lf-hero__media">
          <img class="lf-hero__image" src={@image_src} alt={@image_alt} />
        </div>
      <% end %>
    </section>
    """
  end

  defp validate_contract!(assigns) do
    validate_heading_level!(assigns.heading_level)
    validate_image_alt!(assigns.image_src, assigns.image_alt)
    validate_slot_cardinality!(assigns.primary_action, "primary_action")
    validate_slot_cardinality!(assigns.secondary_action, "secondary_action")
  end

  defp validate_heading_level!(level) when is_integer(level) and level in 1..6, do: :ok

  defp validate_heading_level!(_) do
    raise ArgumentError, "heading_level must be an integer between 1 and 6"
  end

  defp validate_image_alt!(nil, _alt), do: :ok
  defp validate_image_alt!(_src, alt) when is_binary(alt), do: :ok

  defp validate_image_alt!(_src, nil) do
    raise ArgumentError, "image_alt is required when image_src is provided"
  end

  defp validate_slot_cardinality!(entries, _name) when length(entries) <= 1, do: :ok

  defp validate_slot_cardinality!(_entries, name) do
    raise ArgumentError, "#{name} accepts at most one slot entry"
  end

  defp render_actions?(primary_action, secondary_action) do
    primary_action != [] or secondary_action != []
  end
end
