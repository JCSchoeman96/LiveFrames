defmodule LiveFramesPreviewWeb.Storybook.Components.MediaCallToAction do
  use PhoenixStorybook.Story, :component

  alias PhoenixStorybook.Stories.{Attr, Slot, Variation}

  @image "/assets/native/hero-demo.svg"
  @heading "Make room for what comes next"

  def function, do: &LiveFrames.Components.Sections.MediaCallToAction.media_call_to_action/1
  def layout, do: :one_column
  def render_source, do: :function

  def attributes do
    [
      %Attr{id: :heading, type: :string, required: true, doc: "Required section heading."},
      %Attr{
        id: :heading_level,
        type: :integer,
        default: 2,
        values: 1..6,
        doc: "Heading element level. The consumer owns document hierarchy."
      },
      %Attr{id: :eyebrow, type: :string, doc: "Optional short label."},
      %Attr{id: :image_1_src, type: :string, required: true, doc: "First image source."},
      %Attr{
        id: :image_1_alt,
        type: :string,
        required: true,
        doc: "First image alternative text."
      },
      %Attr{id: :image_2_src, type: :string, required: true, doc: "Second image source."},
      %Attr{
        id: :image_2_alt,
        type: :string,
        required: true,
        doc: "Second image alternative text."
      },
      %Attr{id: :image_3_src, type: :string, required: true, doc: "Third image source."},
      %Attr{
        id: :image_3_alt,
        type: :string,
        required: true,
        doc: "Third image alternative text."
      },
      %Attr{id: :class, type: :string, doc: "Optional class on the section root."},
      %Attr{id: :rest, type: :global, doc: "Global attributes on the section root."}
    ]
  end

  def slots do
    [
      %Slot{id: :body, required: false, doc: "Optional caller-owned supporting content."},
      %Slot{
        id: :primary_action,
        required: true,
        doc:
          "Required caller-owned interactive markup; destination and behavior remain consumer-owned."
      }
    ]
  end

  def variations do
    [
      %Variation{
        id: :default,
        description: "Three-image CTA with synthetic preview media",
        note:
          "Synthetic media and caller-owned preview action. This example does not establish source-image fidelity.",
        attributes: base_attributes(),
        slots: [primary_action_slot()]
      },
      %Variation{
        id: :without_body,
        description: "CTA without the optional body slot",
        attributes: Map.put(base_attributes(), :eyebrow, "A short invitation"),
        slots: [primary_action_slot()]
      },
      %Variation{
        id: :heading_level_variant,
        description: "Consumer-selected level-three heading with body copy",
        attributes:
          base_attributes()
          |> Map.put(:heading_level, 3)
          |> Map.put(:eyebrow, "Start here"),
        slots: [
          "<:body><p>Optional supporting copy for this synthetic preview. <a href=\"#body-preview\">Body link</a></p></:body>",
          primary_action_slot()
        ]
      }
    ]
  end

  defp base_attributes do
    %{
      heading: @heading,
      heading_level: 2,
      image_1_src: @image,
      image_1_alt: "Synthetic green and rust color study, first view",
      image_2_src: @image,
      image_2_alt: "Synthetic green and rust color study, second view",
      image_3_src: @image,
      image_3_alt: "Synthetic green and rust color study, third view"
    }
  end

  defp primary_action_slot do
    "<:primary_action><a href=\"#preview\">Explore the preview</a></:primary_action>"
  end
end
