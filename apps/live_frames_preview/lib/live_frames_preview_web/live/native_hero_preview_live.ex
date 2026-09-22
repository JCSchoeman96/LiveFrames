defmodule LiveFramesPreviewWeb.NativeHeroPreviewLive do
  use LiveFramesPreviewWeb, :live_view

  import LiveFrames.Components.Sections.Hero

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, page_title: "Native Hero Preview")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <link rel="stylesheet" href="/liveframes/library/live_frames/css/live_frames.css" />
    <main data-lf-preview="native-hero">
      <.hero
        heading="Build faster with native LiveFrames"
        lede="Preview harness for library-owned Hero styling. Synthetic media only."
        image_src="/assets/native/hero-demo.svg"
        image_alt=""
      >
        <:primary_action>
          <button type="button">Get started</button>
        </:primary_action>
        <:secondary_action>
          <a href="/">Learn more</a>
        </:secondary_action>
      </.hero>
    </main>
    """
  end
end
