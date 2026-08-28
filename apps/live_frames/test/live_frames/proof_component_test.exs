defmodule LiveFrames.ProofComponentTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest

  test "renders a labelled library-owned proof badge" do
    html =
      render_component(&LiveFrames.ProofComponent.proof_badge/1,
        label: "Library component"
      )

    assert html =~ ~s(data-liveframes-proof="true")
    assert html =~ "Library component"
    assert html =~ "lf-proof-badge"
  end
end
