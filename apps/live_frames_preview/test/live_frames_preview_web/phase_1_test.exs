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

  test "base fidelity Hero route renders generated IR output", %{conn: conn} do
    {:ok, _view, html} = live(conn, "/liveframes/fidelity/hero")

    assert html =~ "data-lf-preview=\"hero-fidelity\""
    assert html =~ "lf-fidelity-node-000001"
    assert html =~ "data-lf-asset-status=\"unresolved\""
    assert html =~ "/assets/fidelity/hero.css"
    assert html =~ "btn--outline"
  end

  test "fidelity Hero initial response has one root document and bootstrap", %{conn: conn} do
    conn = get(conn, "/liveframes/fidelity/hero")

    assert conn.status == 200
    assert conn.resp_body =~ "data-lf-preview=\"hero-fidelity\""
    assert length(Regex.scan(~r/<html(?:\s|>)/i, conn.resp_body)) == 1
    assert length(Regex.scan(~r/<head(?:\s|>)/i, conn.resp_body)) == 1
    assert length(Regex.scan(~r/<body(?:\s|>)/i, conn.resp_body)) == 1

    assert length(
             Regex.scan(
               ~r{<script[^>]*src="/assets/js/app\.js"[^>]*></script>}i,
               conn.resp_body
             )
           ) == 1

    assert length(Regex.scan(~r/data-phx-main(?:\s|>)/i, conn.resp_body)) == 1
  end

  test "development config watches all Phase 1 preview inputs" do
    config = File.read!(Path.expand("../../../../config/dev.exs", __DIR__))

    assert config =~ "tailwind: {Tailwind, :install_and_run, [:storybook"
    assert config =~ "esbuild_app: {Esbuild, :install_and_run, [:app"
    assert config =~ "esbuild_storybook: {Esbuild, :install_and_run, [:storybook"
    assert config =~ "storybook/.*\\.exs$"
  end
end
