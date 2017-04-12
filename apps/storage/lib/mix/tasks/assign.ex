defmodule Mix.Tasks.Assign do
  @moduledoc false

  use Mix.Task

  alias Storage.Assigner

  def run(_) do
    Application.ensure_all_started(:storage)

    Assigner.assign_all()
  end
end
