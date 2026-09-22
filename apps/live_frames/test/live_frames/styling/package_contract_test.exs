defmodule LiveFrames.Styling.PackageContractTest do
  use ExUnit.Case, async: true

  @package_files LiveFrames.MixProject.package()[:files]

  test "hex package files include required styling paths and mix.exs" do
    assert "mix.exs" in @package_files
    assert "lib" in @package_files
    assert "assets/css" in @package_files
    assert "priv/token_maps" in @package_files
    assert "priv/static/live_frames" in @package_files
    refute "README.md" in @package_files
  end

  test "configured package paths exist in the live_frames app" do
    app_root = Path.expand("../../..", __DIR__)

    for relative <- @package_files do
      path = Path.join(app_root, relative)
      assert File.exists?(path), "expected package path #{relative} to exist at #{path}"
    end
  end
end
