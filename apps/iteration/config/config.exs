use Mix.Config

config :iteration, ecto_repos: []

config :iteration, :sender, SMSSender
config :iteration, :storage, Storage.Service
