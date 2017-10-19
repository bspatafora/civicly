use Mix.Config

config :notifier, Notifier, timezone: "America/Chicago"

import_config "#{Mix.env}.exs"
