use Mix.Config

config :core, ecto_repos: []

config :core, :sms_sender, SMSSender
config :core, :storage_service, Storage.Service
