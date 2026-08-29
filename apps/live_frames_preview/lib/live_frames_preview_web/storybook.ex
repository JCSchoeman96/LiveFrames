defmodule LiveFramesPreviewWeb.Storybook do
  use PhoenixStorybook,
    otp_app: :live_frames_preview,
    content_path: Path.expand("../../storybook", __DIR__),
    css_path: "/assets/css/storybook.css",
    js_path: "/assets/js/storybook.js",
    sandbox_class: "live-frames",
    title: "LiveFrames Storybook"
end
