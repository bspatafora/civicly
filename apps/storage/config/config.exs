use Mix.Config

config :storage, Storage,
  adapter: Ecto.Adapters.Postgres,
  username: "bspatafora",
  hostname: "localhost"

config :storage, ecto_repos: [Storage]

import_config "#{Mix.env}.exs"
