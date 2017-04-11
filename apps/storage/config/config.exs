use Mix.Config

config :storage, Storage,
  adapter: Ecto.Adapters.Postgres,
  username: "civically",
  password: "***REMOVED***",
  hostname: "localhost"

config :storage, ecto_repos: [Storage]

config :storage, ben_phone: "16306326718"
config :storage, proxy_phone: "16303200120"

import_config "#{Mix.env}.exs"
