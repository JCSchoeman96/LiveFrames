defmodule LiveFramesPreviewWeb.FidelityPreviewLive do
  use LiveFramesPreviewWeb, :live_view

  embed_templates("fidelity_generated/*")

  @impl true
  def mount(_params, _session, socket), do: {:ok, assign(socket, page_title: "Hero Fidelity")}

  @impl true
  def render(assigns) do
    ~H"""
    <link rel="stylesheet" href="/assets/fidelity/hero.css" />
    <main data-lf-preview="hero-fidelity"><.hero /></main>
    """
  end
end
