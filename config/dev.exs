import Config

port = String.to_integer(System.get_env("PORT", "4000"))

config :live_frames_preview, LiveFramesPreviewWeb.Endpoint,
  server: true,
  debug_errors: true,
  code_reloader: true,
  check_origin: false,
  http: [ip: {127, 0, 0, 1}, port: port]
