Path.join(["rel", "plugins", "*.exs"])
|> Path.wildcard()
|> Enum.map(&Code.eval_file(&1))

use Mix.Releases.Config,
    default_release: :default,
    default_environment: Mix.env()

environment :dev do
  set dev_mode: true
  set include_erts: false
  set cookie: :"OuYDGAxr/A3nGr|!syAxb@sAK&bc/X!Q5[]xQ>=kztWKX}mg>sZGo:wYB8&h7fUS"
end

environment :prod do
  set include_erts: true
  set include_src: false
  set cookie: :"fn5L&:_cs9[CQ}1{1jb>)4qOB)0pCpvpf98pAr_ej6J@f&w1DxtL!<|GJprPFk{K"
end

release :civically do
  set version: "0.1.0"
  set applications: [
    :core,
    :sms_message,
    :sms_receiver,
    :sms_sender,
    :storage,
    :logger_json_file_backend,
    :poison,
    :cowboy,
    :plug,
    :httpoison,
    :ecto,
    :postgrex,
    :uuid
  ]
end

