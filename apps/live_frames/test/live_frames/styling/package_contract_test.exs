defmodule LiveFrames.Styling.PackageContractTest do
  use ExUnit.Case, async: true

  @package_files LiveFrames.MixProject.package()[:files]
  @optional_package_paths ~w(priv/catalogue)

  test "hex package files include required styling paths and mix.exs" do
    assert "mix.exs" in @package_files
    assert "lib" in @package_files
    assert "assets/css" in @package_files
    assert "priv/token_maps" in @package_files
    assert "priv/static/live_frames" in @package_files
    assert "priv/catalogue" in @package_files
    refute "README.md" in @package_files
  end

  test "configured package paths exist in the live_frames app" do
    app_root = Path.expand("../../..", __DIR__)
    optional = MapSet.new(@optional_package_paths)

    for relative <- @package_files do
      path = Path.join(app_root, relative)

      cond do
        relative in optional and not File.exists?(path) ->
          :ok

        relative in optional ->
          assert File.dir?(path),
                 "expected optional package path #{relative} to be a directory at #{path}"

        true ->
          assert File.exists?(path), "expected package path #{relative} to exist at #{path}"
      end
    end
  end

  test "live_frames does not depend on preview or storybook apps" do
    deps = LiveFrames.MixProject.project()[:deps]
    dep_apps = Enum.map(deps, &elem(&1, 0))

    refute :live_frames_preview in dep_apps
    refute :phoenix_storybook in dep_apps
  end
end
