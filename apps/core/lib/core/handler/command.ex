defmodule Core.Handler.Command do
  @moduledoc false

  alias Core.{CommandParser, Sender}
  alias Iteration.{Assigner, Notifier}
  alias Strings, as: S

  @storage Application.get_env(:core, :storage)

  def handle(message) do
    case CommandParser.parse(message.text) do
      {:add, name, phone} ->
        attempt_user_insert(name, phone, message)
      {:msg, phone, text} ->
        Sender.send_message(text, [phone], message)
      {:new, number, question} ->
        Assigner.group_by_twos
        Notifier.notify(question, number)
      {:invalid} ->
        Sender.send_command_output(S.invalid_command(), message)
    end
  end

  defp attempt_user_insert(name, phone, message) do
    case @storage.insert_user(name, phone) do
      {:ok, user} ->
        Sender.send_command_output(S.user_added(user.name), message)
        Sender.send_message(S.welcome(), [phone], message)
      {:error, _} ->
        Sender.send_command_output(S.insert_failed(), message)
    end
  end
end
