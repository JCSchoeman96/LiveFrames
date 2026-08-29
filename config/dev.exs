import Config

port = String.to_integer(System.get_env("PORT", "4000"))

config :live_frames_preview, LiveFramesPreviewWeb.Endpoint,
  server: true,
  debug_errors: true,
  code_reloader: true,
  check_origin: false,
  secret_key_base: "liveframes-development-secret-key-base-please-change-locally-0123456789",
  http: [ip: {127, 0, 0, 1}, port: port],
  watchers: [
    tailwind: {Tailwind, :install_and_run, [:storybook, ~w(--watch)]},
    esbuild_app: {Esbuild, :install_and_run, [:app, ~w(--watch --sourcemap=inline)]},
    esbuild_storybook: {Esbuild, :install_and_run, [:storybook, ~w(--watch --sourcemap=inline)]}
  ],
  live_reload: [
    patterns: [
      ~r"priv/static/.*(js|css)$",
      ~r"lib/live_frames_preview_web/.*(ex|heex)$",
      ~r"storybook/.*\.exs$"
    ]
  ]
