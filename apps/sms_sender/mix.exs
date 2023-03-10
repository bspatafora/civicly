defmodule SMSSender.Mixfile do
  use Mix.Project

  def project do
    [app: :sms_sender,
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
     mod: {SMSSender.Supervisor, []}]
  end

  defp deps do
    [{:sms_message, in_umbrella: true},
     {:httpoison, "~> 0.11.0"},
     {:poison, "~> 2.2"}]
  end
end
