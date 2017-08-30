defmodule Mix.Tasks.NewIteration do
  @moduledoc false

  use Mix.Task

  alias Iteration.Assigner
  alias Iteration.Notifier

  def run(args) do
    Application.ensure_all_started(:storage)
    Application.ensure_all_started(:sms_sender)

    number = Enum.at(args, 0)
    question = Enum.at(args, 1)

    cond do
      number == nil ->
        output("You forgot to include the number")
      question == nil ->
        output("You forgot to include the question")
      !String.ends_with?(question, "?") ->
        output("That question doesn't look right. Where's the question mark?")
      true ->
        start_iteration(number, question)
        output("Iteration #{number} has begun")
    end
  end

  defp output(text) do
    IO.puts(text)
  end

  defp start_iteration(number, question) do
    Assigner.group_by_twos()
    Notifier.notify(number, question)
  end
end
