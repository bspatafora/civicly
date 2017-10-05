use Mix.Config

config :logger,
  backends: [{LoggerJSONFileBackend, :json}],
  level: :info

config :logger, :json,
  level: :info,
  metadata_triming: false,
  path: "/home/bspatafora/civically.log"
