defmodule Mix.Tasks.Notify do
  @moduledoc false

  use Mix.Task

  alias Iteration.Notifier

  def run(args) do
    Application.ensure_all_started(:storage)
    Application.ensure_all_started(:sms_sender)

    question = Enum.at(args, 0)

    cond do
      question == nil ->
        output("You forgot to include the question")
      !String.ends_with?(question, "?") ->
        output("That question doesn't look right. Where's the question mark?")
      true ->
        Notifier.notify(question)
        output("Users notified")
    end
  end

  defp output(string) do
    IO.puts(string)
  end
end
