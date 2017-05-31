use Mix.Config

config :sms_sender, :host, "108.65.237.138"
config :sms_sender, :port, "9001"
config :sms_sender, :path, "/send"

import_config "#{Mix.env}.exs"
