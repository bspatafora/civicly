use Mix.Config

config :core, ecto_repos: []

config :core, :sender, SMSSender
config :core, :storage, Storage.Service
