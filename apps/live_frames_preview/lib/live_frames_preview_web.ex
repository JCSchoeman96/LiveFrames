defmodule LiveFramesPreviewWeb do
  def router do
    quote do
      use Phoenix.Router
      import Plug.Conn
      import Phoenix.Controller
      import Phoenix.LiveView.Router
    end
  end

  def controller do
    quote do
      use Phoenix.Controller, formats: [], layouts: []
      import Plug.Conn
    end
  end

  def live_view do
    quote do
      use Phoenix.LiveView
      import Phoenix.Component
      alias Phoenix.LiveView.JS
    end
  end

  def html do
    quote do
      use Phoenix.Component
    end
  end

  defmacro __using__(which) when which in [:controller, :router, :live_view, :html] do
    apply(__MODULE__, which, [])
  end
end
