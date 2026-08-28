defmodule LiveFramesPreviewWeb.RuntimeConfigTest do
  use ExUnit.Case, async: false

  @runtime_config Path.expand("../../../../config/runtime.exs", __DIR__)
  @secret_env "LIVE_FRAMES_SECRET_KEY_BASE"

  setup do
    previous_secret = System.get_env(@secret_env)
    System.delete_env(@secret_env)

    on_exit(fn ->
      if previous_secret do
        System.put_env(@secret_env, previous_secret)
      else
        System.delete_env(@secret_env)
      end
    end)

    :ok
  end

  test "production runtime config fails when the secret is missing" do
    assert_raise System.EnvError, ~r/LIVE_FRAMES_SECRET_KEY_BASE/, fn ->
      Config.Reader.read!(@runtime_config, env: :prod)
    end
  end

  test "production runtime config uses the supplied secret" do
    secret = "runtime-test-secret"
    System.put_env(@secret_env, secret)

    config = Config.Reader.read!(@runtime_config, env: :prod)

    assert get_in(config, [:live_frames_preview, LiveFramesPreviewWeb.Endpoint, :secret_key_base]) ==
             secret
  end
end
