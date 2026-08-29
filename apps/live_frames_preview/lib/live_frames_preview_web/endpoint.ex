defmodule LiveFramesPreviewWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :live_frames_preview

  socket "/live", Phoenix.LiveView.Socket

  plug Plug.Static,
    at: "/",
    from: :live_frames_preview,
    gzip: false,
    only: ~w(assets robots.txt)

  plug Plug.Session,
    store: :cookie,
    key: "_live_frames_key",
    signing_salt: "liveframes-session"

  plug Plug.RequestId
  plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()

  plug Plug.MethodOverride
  plug Plug.Head

  if code_reloading? do
    plug Phoenix.LiveReloader
  end

  plug LiveFramesPreviewWeb.Router
end
