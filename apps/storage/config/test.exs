use Mix.Config

config :storage, Storage,
  database: "civically_test",
  pool: Ecto.Adapters.SQL.Sandbox
