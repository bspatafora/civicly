use Mix.Config

config :sms_sender, :path, "/send"

import_config "#{Mix.env}.exs"
