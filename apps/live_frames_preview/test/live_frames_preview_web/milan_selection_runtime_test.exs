defmodule LiveFramesPreviewWeb.MilanSelectionRuntimeTest do
  use ExUnit.Case, async: false

  test "preview imports the LiveFrames colocated hooks into LiveSocket" do
    repository_root = Path.expand("../../../..", __DIR__)
    app_js_path = Path.join(repository_root, "apps/live_frames_preview/assets/js/app.js")
    app_js = File.read!(app_js_path)

    assert app_js =~
             ~s|import { hooks as colocatedHooks } from "phoenix-colocated/live_frames";|

    assert app_js =~ "hooks: { ...colocatedHooks }"
    assert app_js =~ "params: { _csrf_token: csrfToken?.getAttribute(\"content\") }"

    {output, status} =
      System.cmd("mix", ["esbuild", "app"],
        cd: repository_root,
        env: [{"MIX_ENV", Atom.to_string(Mix.env())}],
        stderr_to_stdout: true
      )

    assert status == 0, output

    manifest_path =
      Path.join([Mix.Project.build_path(), "phoenix-colocated", "live_frames", "index.js"])

    assert File.regular?(manifest_path)
  end
end
