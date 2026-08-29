defmodule LiveFrames.ProofComponent do
  use Phoenix.Component

  attr(:label, :string, default: "LiveFrames library")
  attr(:class, :string, default: nil)

  @doc "Renders the internal Phase 1 library-to-preview proof marker."
  def proof_badge(assigns) do
    ~H"""
    <span class={[@class, "lf-proof-badge"]} data-liveframes-proof="true">
      <span class="lf-proof-badge__mark" aria-hidden="true">+</span>
      <span><%= @label %></span>
    </span>
    """
  end
end
