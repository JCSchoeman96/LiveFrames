defmodule LiveFramesPreviewWeb.NativeHeroPreviewLiveTest do
  use LiveFramesPreviewWeb.ConnCase, async: true

  test "GET /liveframes/native/hero serves the native hero harness", %{conn: conn} do
    conn = get(conn, "/liveframes/native/hero")
    response = html_response(conn, 200)

    assert response =~ "lf-hero"
    assert response =~ ~s(href="/liveframes/library/live_frames/css/live_frames.css")
    assert response =~ "lf-hero__action--primary"
    assert response =~ "lf-hero__action--secondary"
    refute response =~ "lf-fidelity"
  end

  test "library css artifact is reachable through preview static host", %{conn: conn} do
    conn = get(conn, "/liveframes/library/live_frames/css/live_frames.css")
    assert response(conn, 200)
    assert get_resp_header(conn, "content-type") |> hd() =~ "text/css"
    assert conn.resp_body =~ ".lf-hero"
  end
end
