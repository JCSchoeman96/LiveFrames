import Config

config :live_frames_preview, LiveFramesPreviewWeb.Endpoint,
  server: false,
  http: [ip: {127, 0, 0, 1}, port: 4001],
  secret_key_base: "liveframes-test-secret-key-base-liveframes-test-secret-key-base-1234"

config :phoenix, :plug_init_mode, :runtime
