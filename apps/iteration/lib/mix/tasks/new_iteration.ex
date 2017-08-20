defmodule Mix.Tasks.NewIteration do
  @moduledoc false

  use Mix.Task

  alias Iteration.Assigner
  alias Iteration.Notifier

  def run(args) do
    Application.ensure_all_started(:storage)
    Application.ensure_all_started(:sms_sender)

    question = List.first(args)
    year = List.last(args)

    Assigner.group_by_twos()
    Notifier.notify(question, year)
  end
end
