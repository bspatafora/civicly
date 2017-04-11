use Mix.Config

config :logger,
  backends: [{LoggerJSONFileBackend, :json}]

config :logger, :json,
  level: :info,
  metadata_triming: false,
  path: "/home/bspatafora/civically.log"
