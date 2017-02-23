use Mix.Config

config :logger, level: :info

config :storage, Storage,
  database: "civically_test",
  pool: Ecto.Adapters.SQL.Sandbox
