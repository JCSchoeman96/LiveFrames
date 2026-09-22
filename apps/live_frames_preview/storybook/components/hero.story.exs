defmodule LiveFramesPreviewWeb.Storybook.Components.Hero do
  use PhoenixStorybook.Story, :component

  alias PhoenixStorybook.Stories.{Attr, Slot, Variation}

  @synthetic_image "/assets/native/hero-demo.svg"
  @default_heading "Build faster with native LiveFrames"
  @default_lede "Preview harness for library-owned Hero styling. Synthetic media only."

  @consumer_slot_doc """
  Consumer owns accessible label, destination/navigation, events, and application behavior.
  LiveFrames owns presentation and layout. Each slot accepts at most one entry.
  """

  def function, do: &LiveFrames.Components.Sections.Hero.hero/1
  def layout, do: :one_column
  def render_source, do: :function

  def attributes do
    [
      %Attr{id: :heading, type: :string, required: true, doc: "Required section heading text."},
      %Attr{
        id: :heading_level,
        type: :integer,
        default: 2,
        values: 1..6,
        doc: "Heading element level (1..6). Consumer owns document hierarchy."
      },
      %Attr{id: :lede, type: :string, doc: "Optional supporting paragraph."},
      %Attr{
        id: :image_src,
        type: :string,
        doc: "Optional image URL. When set, image_alt must be a binary."
      },
      %Attr{
        id: :image_alt,
        type: :string,
        doc:
          "Required when image_src is set. Use \"\" for decorative or non-empty text for informative images."
      },
      %Attr{id: :id, type: :string, doc: "Optional root element id."},
      %Attr{id: :class, type: :string, doc: "Optional extra classes on the Hero root."},
      %Attr{id: :rest, type: :global, doc: "Global HTML attributes forwarded to the Hero root."}
    ]
  end

  def slots do
    [
      %Slot{id: :primary_action, required: false, doc: @consumer_slot_doc},
      %Slot{id: :secondary_action, required: false, doc: @consumer_slot_doc}
    ]
  end

  def variations do
    [
      %Variation{
        id: :default,
        description: "Full representative Hero with synthetic preview media",
        note: """
        Uses repository-owned synthetic preview media only. This is not attachment 880 and does not establish source-image fidelity.
        Action behavior (navigation, events, labels) is consumer-owned. Heading hierarchy is consumer-owned.
        Theme overrides require consumer re-verification.
        """,
        attributes: %{
          heading: @default_heading,
          heading_level: 2,
          lede: @default_lede,
          image_src: @synthetic_image,
          image_alt: ""
        },
        slots: [
          """
          <:primary_action>
            <button type="button">Get started</button>
          </:primary_action>
          """,
          """
          <:secondary_action>
            <a href="/">Learn more</a>
          </:secondary_action>
          """
        ]
      },
      %Variation{
        id: :informative_media,
        description: "Informative image with non-empty alt text",
        note: """
        Demonstrates the informative image contract with synthetic verification media only (not attachment 880).
        Image semantic decision is consumer-owned.
        """,
        attributes: %{
          heading: @default_heading,
          heading_level: 2,
          lede: @default_lede,
          image_src: @synthetic_image,
          image_alt: "Synthetic LiveFrames hero verification graphic for Storybook preview"
        },
        slots: [
          """
          <:primary_action>
            <button type="button">Get started</button>
          </:primary_action>
          """,
          """
          <:secondary_action>
            <a href="/">Learn more</a>
          </:secondary_action>
          """
        ]
      },
      %Variation{
        id: :no_media,
        description: "Valid Hero without media",
        note: """
        No placeholder media. Heading hierarchy (level 3 here) is consumer-owned.
        Action behavior remains consumer-owned when slots are supplied.
        """,
        attributes: %{
          heading: "Ship sections without backdrop media",
          heading_level: 3,
          lede: "Hero remains valid when image_src and image_alt are omitted."
        },
        slots: [
          """
          <:primary_action>
            <button type="button">Get started</button>
          </:primary_action>
          """,
          """
          <:secondary_action>
            <a href="/">Learn more</a>
          </:secondary_action>
          """
        ]
      },
      %Variation{
        id: :minimal,
        description: "Required heading only",
        note: """
        Minimal valid Hero: heading only. No lede, media, or actions. No Storybook placeholders masquerading as component content.
        """,
        attributes: %{
          heading: "Minimal native Hero"
        }
      }
    ]
  end
end
