defmodule Core.Mixfile do
  use Mix.Project

  def project do
    [app: :core,
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
    [extra_applications: [:logger]]
  end

  defp deps do
    [{:sms_message, in_umbrella: true},
     {:sms_sender, in_umbrella: true},
     {:storage, in_umbrella: true},
     {:bypass, "~> 0.6", only: :test}]
  end
end
