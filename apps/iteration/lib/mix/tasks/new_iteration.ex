defmodule Mix.Tasks.NewIteration do
  @moduledoc false

  use Mix.Task

  alias Iteration.Assigner
  alias Iteration.Notifier

  def run(question) do
    Application.ensure_all_started(:storage)
    Application.ensure_all_started(:sms_sender)

    Assigner.group_by_twos()
    Notifier.notify(question)
  end
end
