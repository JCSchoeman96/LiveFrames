import Config

if config_env() == :prod do
  config :live_frames_preview, LiveFramesPreviewWeb.Endpoint,
    secret_key_base: System.fetch_env!("LIVE_FRAMES_SECRET_KEY_BASE")
end
