defmodule SMSReceiver.Mixfile do
  use Mix.Project

  def project do
    [app: :sms_receiver,
     version: "0.1.0",
     build_path: "../../_build",
     config_path: "../../config/config.exs",
     deps_path: "../../deps",
     lockfile: "../../mix.lock",
     elixir: "~> 1.4",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps()]
  end

  def application do
    [extra_applications: [:logger],
     mod: {SMSReceiver.Supervisor, []}]
  end

  defp deps do
    [{:core, in_umbrella: true},
     {:sms_message, in_umbrella: true},
     {:cowboy, "~> 1.1"},
     {:plug, "~> 1.3"},
     {:bypass, "~> 0.6", only: :test}]
  end
end
