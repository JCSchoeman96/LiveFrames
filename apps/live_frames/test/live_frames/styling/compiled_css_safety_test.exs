defmodule LiveFrames.Styling.CompiledCssSafetyTest do
  use ExUnit.Case, async: true

  @compiled Path.expand("../../../priv/static/live_frames/css/live_frames.css", __DIR__)

  test "compiled package css does not ship global preflight selectors" do
    css = File.read!(@compiled)

    refute css =~ "html, :host"
    refute css =~ "*, ::after, ::before"
    refute css =~ "@layer base"
  end
end
