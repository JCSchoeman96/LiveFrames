defmodule LiveFrames.Components.Sections.Hero do
  @moduledoc """
  Dark section Hero for Phoenix applications.

  Call `hero/1` with required `heading`, optional `heading_level` (default `2`,
  integers `1..6`), optional `lede`, and optional `image_src` / `image_alt`.
  When `image_src` is present, `image_alt` must be a binary: use `""` for a
  decorative image or non-empty text for an informative image. Omit `image_src`
  for a Hero without media.

  Slots `primary_action` and `secondary_action` each accept at most one entry.
  Supply one native interactive root per slot (for example a `<button>` or
  `<.link>`). LiveFrames styles presentation only; destinations, events, and
  labels are consumer-owned.

  Requires LiveFrames CSS (precompiled or source-built). Theme customization
  uses public `--lf-*` variables; see `docs/16_PACKAGE_AND_GENERATOR_MODEL.md`
  and `docs/11_CSS_AND_TAILWIND_STRATEGY.md`.
  """

  use Phoenix.Component

  Module.register_attribute(
    __MODULE__,
    :liveframes_public_contract_metadata,
    persist: true
  )

  @liveframes_public_contract_metadata %{
    hero: %{
      slot_cardinality: %{
        "primary_action" => {0, 1},
        "secondary_action" => {0, 1}
      },
      capabilities: [
        "liveframes.consumer.owns_action_navigation_and_events",
        "liveframes.consumer.owns_global_root_attributes",
        "liveframes.content.plain_text_heading_and_lede",
        "liveframes.integration.requires_liveframes_css",
        "liveframes.validation.argument_error_on_contract_violation"
      ],
      css_theme_contract: [
        "--lf-action-primary-background",
        "--lf-action-primary-background-hover",
        "--lf-action-primary-border",
        "--lf-action-primary-border-style",
        "--lf-action-primary-border-width",
        "--lf-action-primary-focus",
        "--lf-action-primary-font-size",
        "--lf-action-primary-font-weight",
        "--lf-action-primary-line-height",
        "--lf-action-primary-min-width",
        "--lf-action-primary-padding-block",
        "--lf-action-primary-padding-inline",
        "--lf-action-primary-radius",
        "--lf-action-primary-text",
        "--lf-action-secondary-background",
        "--lf-action-secondary-background-hover",
        "--lf-action-secondary-border",
        "--lf-action-secondary-border-hover",
        "--lf-action-secondary-focus",
        "--lf-action-secondary-text",
        "--lf-action-secondary-text-hover",
        "--lf-color-background-ultra-dark",
        "--lf-color-heading-on-dark",
        "--lf-color-text-on-dark",
        "--lf-layout-container-max-width",
        "--lf-space-container-gap",
        "--lf-space-content-gap",
        "--lf-space-gutter",
        "--lf-space-section-padding-block",
        "--lf-typography-body-line-height",
        "--lf-typography-body-size",
        "--lf-typography-display-line-height",
        "--lf-typography-display-size",
        "--lf-typography-display-weight"
      ],
      global_prefixes: []
    }
  }

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

  @doc """
  Renders the Hero section.

  Public attrs: `heading`, `heading_level`, `lede`, `image_src`, `image_alt`,
  `id`, `class`, and global `rest`. Slots: `primary_action`, `secondary_action`
  (0 or 1 entry each). See module documentation for image-alt rules and CSS requirements.
  """
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

  defp validate_slot_cardinality!([], _name), do: :ok
  defp validate_slot_cardinality!([_single], _name), do: :ok

  defp validate_slot_cardinality!(_entries, name) do
    raise ArgumentError, "#{name} accepts at most one slot entry"
  end

  defp render_actions?(primary_action, secondary_action) do
    primary_action != [] or secondary_action != []
  end
end
