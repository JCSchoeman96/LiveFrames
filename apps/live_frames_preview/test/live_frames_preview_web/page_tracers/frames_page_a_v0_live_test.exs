defmodule LiveFramesPreviewWeb.FramesPageAV0LiveTest do
  use LiveFramesPreviewWeb.ConnCase, async: true

  test "GET /liveframes/pages/frames-a-v0 renders the synthetic Page A composition", %{conn: conn} do
    conn = get(conn, "/liveframes/pages/frames-a-v0")
    response = html_response(conn, 200)

    assert length(Regex.scan(~r/<section[^>]*class="[^"]*\blf-hero\b/, response)) == 1
    assert length(Regex.scan(~r/class="[^"]*\bpage-a-cta-a\b/, response)) == 1
    assert length(Regex.scan(~r/class="[^"]*\bpage-a-cta-b\b/, response)) == 1

    assert response =~ "Page A caller-owned Hero heading"
    assert response =~ "Page A caller-owned CTA A heading"
    assert response =~ "Page A caller-owned CTA B heading"

    assert length(Regex.scan(~r/href="\/page-a\/cta-a"/, response)) == 1
    assert length(Regex.scan(~r/href="\/page-a\/cta-b"/, response)) == 1
    assert response =~ "CTA A body owned by the preview caller."
    assert response =~ "CTA B body owned by the preview caller."

    assert length(
             Regex.scan(
               ~r/href="\/liveframes\/library\/live_frames\/css\/live_frames\.css"/,
               response
             )
           ) == 1

    refute response =~ "private_reference/"
    refute response =~ "bricks-component-"
    refute response =~ "ComponentizationPlan"
    refute response =~ "DesignDocument"
  end
end
