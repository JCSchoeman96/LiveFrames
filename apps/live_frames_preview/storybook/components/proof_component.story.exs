defmodule LiveFramesPreviewWeb.Storybook.Components.ProofComponent do
  use PhoenixStorybook.Story, :component

  alias PhoenixStorybook.Stories.Variation

  def function, do: &LiveFrames.ProofComponent.proof_badge/1

  def variations do
    [
      %Variation{
        id: :default,
        attributes: %{label: "Library component"}
      }
    ]
  end

  def layout, do: :one_column
  def render_source, do: :function
end
