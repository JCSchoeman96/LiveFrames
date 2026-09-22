defmodule LiveFrames.Styling.PackageContractTest do
  use ExUnit.Case, async: true

  test "hex package files include styling source, map, and compiled artifact paths" do
    files = LiveFrames.MixProject.package()[:files]

    assert "assets/css" in files
    assert "priv/token_maps" in files
    assert "priv/static/live_frames" in files
    assert "lib" in files
  end
end
