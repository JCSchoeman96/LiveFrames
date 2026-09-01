defmodule LiveFramesPreviewWeb.Router do
  use LiveFramesPreviewWeb, :router

  import PhoenixStorybook.Router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {LiveFramesPreviewWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  scope "/" do
    storybook_assets()
  end

  scope "/", LiveFramesPreviewWeb do
    pipe_through :browser

    get "/", PageController, :home
    get "/health", PageController, :health
    live("/liveframes/lab", ConversionLabLive, :index)
    live("/liveframes/fidelity/hero", FidelityPreviewLive, :index)
    live_storybook("/storybook", backend_module: LiveFramesPreviewWeb.Storybook)
  end
end
