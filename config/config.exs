import Config

config :phoenix, :json_library, Jason

config :tailwind,
  version: "4.1.12",
  storybook: [
    args: ~w(--input=assets/css/storybook.css --output=priv/static/assets/css/storybook.css),
    cd: Path.expand("../apps/live_frames_preview", __DIR__)
  ]

config :esbuild,
  version: "0.25.0",
  app: [
    args: ~w(js/app.js --bundle --target=es2022 --outdir=../priv/static/assets/js),
    cd: Path.expand("../apps/live_frames_preview/assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ],
  storybook: [
    args: ~w(js/storybook.js --bundle --target=es2022 --outdir=../priv/static/assets/js),
    cd: Path.expand("../apps/live_frames_preview/assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

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
