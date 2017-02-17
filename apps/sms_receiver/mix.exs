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
     mod: {SMSReceiver, []}]
  end

  defp deps do
    [{:cowboy, "~> 1.1"},
     {:plug, "~> 1.3"}]
  end
end
