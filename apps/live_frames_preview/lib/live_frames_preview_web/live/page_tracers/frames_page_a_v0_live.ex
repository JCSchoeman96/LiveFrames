defmodule LiveFramesPreviewWeb.PageTracers.FramesPageAV0Live do
  use LiveFramesPreviewWeb, :live_view

  import LiveFrames.Components.Sections.Hero
  import LiveFrames.Components.Sections.MediaCallToAction

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, page_title: "Page A Preview")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <link rel="stylesheet" href="/liveframes/library/live_frames/css/live_frames.css" />
    <main data-lf-preview="frames-page-a-v0">
      <.hero
        heading="Page A caller-owned Hero heading"
        lede="Synthetic preview content for the Page A composition."
        image_src="/assets/native/hero-demo.svg"
        image_alt="Abstract shapes in the preview image"
      >
        <:primary_action><a href="/page-a/hero">Explore the page</a></:primary_action>
      </.hero>

      <.media_call_to_action
        class="page-a-cta-a"
        heading="Page A caller-owned CTA A heading"
        image_1_src="/assets/native/hero-demo.svg?cta=a-1"
        image_1_alt="Abstract shapes for CTA A image one"
        image_2_src="/assets/native/hero-demo.svg?cta=a-2"
        image_2_alt="Abstract shapes for CTA A image two"
        image_3_src="/assets/native/hero-demo.svg?cta=a-3"
        image_3_alt="Abstract shapes for CTA A image three"
      >
        <:body><p>CTA A body owned by the preview caller.</p></:body>
        <:primary_action><a href="/page-a/cta-a">Continue with CTA A</a></:primary_action>
      </.media_call_to_action>

      <.media_call_to_action
        class="page-a-cta-b"
        heading="Page A caller-owned CTA B heading"
        image_1_src="/assets/native/hero-demo.svg?cta=b-1"
        image_1_alt="Abstract shapes for CTA B image one"
        image_2_src="/assets/native/hero-demo.svg?cta=b-2"
        image_2_alt="Abstract shapes for CTA B image two"
        image_3_src="/assets/native/hero-demo.svg?cta=b-3"
        image_3_alt="Abstract shapes for CTA B image three"
      >
        <:body><p>CTA B body owned by the preview caller.</p></:body>
        <:primary_action><a href="/page-a/cta-b">Continue with CTA B</a></:primary_action>
      </.media_call_to_action>
    </main>
    """
  end
end
