defmodule LiveFramesPreviewWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :live_frames_preview

  socket "/live", Phoenix.LiveView.Socket

  plug Plug.Static,
    at: "/",
    from: :live_frames_preview,
    gzip: false,
    only: ~w(robots.txt)

  plug Plug.RequestId
  plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()

  plug Plug.MethodOverride
  plug Plug.Head

  plug LiveFramesPreviewWeb.Router
end
