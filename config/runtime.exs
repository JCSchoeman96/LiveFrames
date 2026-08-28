import Config

# Production deployment can provide a real secret at runtime. Development and
# test use the explicit values in config/config.exs and config/test.exs.
if config_env() == :prod do
  if secret_key_base = System.get_env("LIVE_FRAMES_SECRET_KEY_BASE") do
    config :live_frames_preview, LiveFramesPreviewWeb.Endpoint, secret_key_base: secret_key_base
  end
end
