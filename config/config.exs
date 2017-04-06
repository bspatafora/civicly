use Mix.Config

config :logger,
  backends: [{LoggerJSONFileBackend, :json}]

config :logger, :json,
  metadata_triming: false

import_config "#{Mix.env}.exs"
import_config "../apps/*/config/config.exs"
