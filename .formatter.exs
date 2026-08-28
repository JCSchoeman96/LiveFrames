[
  inputs: [
    "{mix,.formatter}.exs",
    "{config,lib,test}/**/*.{ex,exs}",
    "apps/*/{mix,.formatter}.exs",
    "apps/*/{lib,test}/**/*.{ex,exs}",
    "apps/*/storybook/**/*.exs"
  ],
  locals_without_parens: [
    get: 3,
    plug: 1,
    plug: 2,
    pipe_through: 1,
    socket: 2
  ]
]
