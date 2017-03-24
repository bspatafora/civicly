use Mix.Config

config :logger,
  backends: [{LoggerJSONFileBackend, :json}]

config :logger, :json,
  path: "/home/bspatafora/civically.log",
  level: :info,
  metadata_triming: false

import_config "../apps/*/config/config.exs"
