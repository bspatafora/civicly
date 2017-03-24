defmodule Civically.Mixfile do
  use Mix.Project

  def project do
    [apps_path: "apps",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps(),
     aliases: aliases()]
  end

  defp deps do
    [{:logger_json_file_backend, "~> 0.1.4"},
     {:distillery, "~> 1.0"}]
  end

  defp aliases do
    [rebuild_dev: &rebuild_dev/1,
     rebuild_test: &rebuild_test/1]
  end

  defp rebuild_dev(_) do
    rebuild("dev")
  end

  defp rebuild_test(_) do
    rebuild("test")
  end

  defp rebuild(env) do
    Mix.shell.cmd "MIX_ENV=#{env} mix ecto.drop"
    Mix.shell.cmd "MIX_ENV=#{env} mix ecto.create"
    Mix.shell.cmd "MIX_ENV=#{env} mix ecto.migrate"
  end
end
