defmodule Notifier.Mixfile do
  use Mix.Project

  def project do
    [app: :notifier,
     version: "0.1.0",
     build_path: "../../_build",
     config_path: "../../config/config.exs",
     deps_path: "../../deps",
     lockfile: "../../mix.lock",
     elixir: "~> 1.5",
     start_permanent: Mix.env == :prod,
     deps: deps()]
  end

  def application do
    [extra_applications: [:logger],
     mod: {Notifier.Supervisor, []}]
  end

  defp deps do
    [{:core, in_umbrella: true},
     {:quantum, ">= 2.1.1"},
     {:timex, "~> 3.0"}]
  end
end
