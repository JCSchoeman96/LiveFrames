defmodule LiveFramesPreviewWeb.EndpointTest do
  use ExUnit.Case, async: true

  import Plug.Test

  test "preview endpoint boots with the foundation page" do
    conn = conn(:get, "/")
    response = LiveFramesPreviewWeb.Endpoint.call(conn, [])

    assert response.status == 200
    assert response.resp_body =~ "LiveFrames Preview"
  end

  test "health endpoint reports readiness" do
    conn = conn(:get, "/health")
    response = LiveFramesPreviewWeb.Endpoint.call(conn, [])

    assert response.status == 200
    assert response.resp_body == "ok\n"
  end
end
