defmodule Core.Handler.Command do
  @moduledoc false

  alias Core.{CommandParser, Sender}
  alias Core.Action.{End, News}
  alias Iteration.{Assigner, Notifier}
  alias Storage.Service.{CommandHistory, User}
  alias Strings, as: S
  alias Strings.Tutorial, as: T

  def handle(message) do
    CommandHistory.insert(message)

    case CommandParser.parse(message.text) do
      {:add, name, phone} ->
        attempt_user_insert(name, phone, message)
      {:msg, phone, text} ->
        text = S.prepend_civicly(text)
        Sender.send_message(text, [phone], message)
      {:all, text} ->
        text = S.prepend_civicly(text)
        Sender.send_to_all(text, message)
      {:all_active, text} ->
        text = S.prepend_civicly(text)
        Sender.send_to_active(text, message)
      {:new, question} ->
        Assigner.group_by_twos()
        Notifier.notify(question)
      {:notify, question} ->
        Notifier.notify(question)
      :end ->
        End.execute()
      :news ->
        News.send(message)
      :news? ->
        News.check(message)
      {:invalid} ->
        Sender.send_command_output(S.invalid_command(), message)
    end
  end

  defp attempt_user_insert(name, phone, message) do
    case User.insert(name, phone) do
      {:ok, user} ->
        Sender.send_command_output(S.user_added(user.name), message)
        Sender.send_message(T.step_1(), [phone], message)
      {:error, _} ->
        Sender.send_command_output(S.insert_failed(), message)
    end
  end
end
