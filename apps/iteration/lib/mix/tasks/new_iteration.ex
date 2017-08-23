defmodule Mix.Tasks.NewIteration do
  @moduledoc false

  use Mix.Task

  alias Iteration.Assigner
  alias Iteration.Notifier

  def run(args) do
    Application.ensure_all_started(:storage)
    Application.ensure_all_started(:sms_sender)

    question = Enum.at(args, 0)
    year = Enum.at(args, 1)

    cond do
      question == nil ->
        output("You forgot to include the question")
      !String.ends_with?(question, "?") ->
        output("That question doesn't look right. Where's the question mark?")
      year == nil ->
        output("You forgot to include the year")
      !String.match?(year, ~r/^\d{4}$/) ->
        output("That year doesn't look right")
      true ->
        start_iteration(question, year)
        output("Iteration #{year} has begun")
    end
  end

  defp output(text) do
    IO.puts(text)
  end

  defp start_iteration(question, year) do
    Assigner.group_by_twos()
    Notifier.notify(question, year)
  end
end
