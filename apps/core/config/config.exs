use Mix.Config

config :core, ecto_repos: []

config :core, :sender, SMSSender

config :core, :news_api_origin, "https://newsapi.org:443"
config :core, :news_api_key, "***REMOVED***"

config :core, :googl_origin, "https://www.googleapis.com:443"
config :core, :googl_key, "***REMOVED***"

import_config "#{Mix.env}.exs"
