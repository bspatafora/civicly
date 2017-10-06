defmodule Core.Handler.Command do
  @moduledoc false

  alias Core.{CommandParser, Sender}
  alias Core.APIClient.{Googl, NewsAPI}
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
        Sender.send_to_active(S.iteration_end(), message)
        Service.inactivate_all_conversations()
      :news ->
        Sender.send_to_active(news(), message)
      :news? ->
        Sender.send_command_output(news(), message)
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

  defp news do
    {title, url} = NewsAPI.ap_top
    S.news(title, Googl.shorten(url))
  end
end
