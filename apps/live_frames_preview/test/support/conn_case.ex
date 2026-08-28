defmodule LiveFramesPreviewWeb.ConnCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      @endpoint LiveFramesPreviewWeb.Endpoint
      import Plug.Conn
      import Phoenix.ConnTest
      import Phoenix.LiveViewTest
    end
  end

  setup do
    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end
end
