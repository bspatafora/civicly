use Mix.Config

config :sms_sender, :port, "9001"
config :sms_sender, :path, "/send"
config :sms_sender, :rate_limit, 3000

import_config "#{Mix.env}.exs"
