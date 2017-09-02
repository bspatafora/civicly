defmodule Core.Handler.Command do
  @moduledoc false

  alias Core.{CommandParser, Sender}
  alias Iteration.{Assigner, Notifier}
  alias Storage.Service
  alias Strings, as: S

  @storage Application.get_env(:core, :storage)

  def handle(message) do
    case CommandParser.parse(message.text) do
      {:add, name, phone} ->
        attempt_user_insert(name, phone, message)
      {:msg, phone, text} ->
        text = S.prepend_civicly(text)
        Sender.send_message(text, [phone], message)
      {:new, number, question} ->
        Assigner.group_by_twos()
        Notifier.notify(number, question)
      :end ->
        Service.inactivate_all_conversations()
        Sender.send_to_all(S.iteration_end(), message)
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
