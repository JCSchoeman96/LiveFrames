import Config

config :phoenix, :json_library, Jason

config :live_frames_preview, LiveFramesPreviewWeb.Endpoint,
  adapter: Bandit.PhoenixAdapter,
  url: [host: "localhost"],
  http: [ip: {127, 0, 0, 1}, port: 4000],
  secret_key_base: "liveframes-phase-0-secret-key-base-please-change-in-production-0123456789",
  pubsub_server: LiveFramesPreview.PubSub,
  live_view: [signing_salt: "liveframes-phase-0"]

if config_env() == :prod do
  import_config "runtime.exs"
else
  import_config "#{config_env()}.exs"
end
