defmodule LiveFramesPreviewWeb.Router do
  use LiveFramesPreviewWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
  end

  scope "/", LiveFramesPreviewWeb do
    pipe_through :browser

    get "/", PageController, :home
    get "/health", PageController, :health
  end
end
