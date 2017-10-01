defmodule Mix.Tasks.Assign do
  @moduledoc false

  use Mix.Task

  alias Iteration.Assigner

  def run(_) do
    Application.ensure_all_started(:storage)

    Assigner.group_by_twos()

    IO.puts("Partners assigned")
  end
end
