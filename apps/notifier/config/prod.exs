use Mix.Config

alias Core.Action.News

config :notifier, Notifier,
  jobs:
    [{"0 12 * * *", {News, :send, []}}]
