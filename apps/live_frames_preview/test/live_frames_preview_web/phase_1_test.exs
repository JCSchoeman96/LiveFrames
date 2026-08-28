defmodule LiveFramesPreviewWeb.Phase1Test do
  use LiveFramesPreviewWeb.ConnCase, async: true

  test "storybook route is mounted", %{conn: conn} do
    conn = get(conn, "/storybook/components/proof_component")

    assert conn.status == 200
    assert conn.resp_body =~ "LiveFrames Storybook"
  end

  test "storybook has exactly one Phase 1 story", _context do
    stories =
      Path.wildcard(Path.expand("../../storybook/**/*.story.exs", __DIR__))

    assert stories == [
             Path.expand(
               "../../storybook/components/proof_component.story.exs",
               __DIR__
             )
           ]
  end

  test "conversion lab renders the static inspection regions", %{conn: conn} do
    {:ok, _view, html} = live(conn, "/liveframes/lab")

    assert html =~ "LiveFrames Conversion Lab"
    assert html =~ "Source metadata"
    assert html =~ "Normalized tokens"
    assert html =~ "Design IR"
    assert html =~ "Diagnostics"
    assert html =~ "Phase 1 shell"
  end
end
