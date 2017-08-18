defmodule Mix.Tasks.NewIteration do
  @moduledoc false

  use Mix.Task

  alias Iteration.Assigner
  alias Iteration.Notifier

  def run(_) do
    Application.ensure_all_started(:storage)

    Assigner.group_by_twos()
    Notifier.notify()
  end
end
