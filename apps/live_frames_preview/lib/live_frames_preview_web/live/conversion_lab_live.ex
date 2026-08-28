defmodule LiveFramesPreviewWeb.ConversionLabLive do
  use LiveFramesPreviewWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, page_title: "Conversion Lab")}
  end
end
