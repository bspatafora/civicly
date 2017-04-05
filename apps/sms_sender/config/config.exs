use Mix.Config

config :sms_sender, :path, "/sms/json"
config :sms_sender, :api_key, "1f55a721"
config :sms_sender, :api_secret, "02de69d6e2fb67cA"

import_config "#{Mix.env}.exs"
