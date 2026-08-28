defmodule LiveFramesTest do
  use ExUnit.Case, async: true

  test "the reusable package exposes its root module" do
    assert Code.ensure_loaded?(LiveFrames)
  end

  test "the reusable package does not declare a preview dependency" do
    mix_file = Path.expand("../mix.exs", __DIR__)

    refute File.read!(mix_file) =~ ":live_frames_preview"
  end
end
