use Mix.Config

config :logger,
  backends: [{LoggerJSONFileBackend, :json}]

config :logger, :json,
  path: "app.log",
  level: :info,
  metadata_triming: false

import_config "../apps/*/config/config.exs"
