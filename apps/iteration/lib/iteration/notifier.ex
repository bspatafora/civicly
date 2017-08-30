defmodule Iteration.Notifier do
  @moduledoc false

  alias Ecto.UUID

  alias Strings, as: S

  @sender Application.get_env(:iteration, :sender)
  @storage Application.get_env(:iteration, :storage)

  def notify(number, question) do
    conversations = @storage.current_conversations()
    Enum.each(conversations, &(notify_users(&1, number, question)))
  end

  defp notify_users(conversation, number, question) do
    shared_params =
      %{sender: conversation.sms_relay.phone,
        sms_relay_ip: conversation.sms_relay.ip,
        timestamp: DateTime.utc_now(),
        uuid: UUID.generate()}

    users = conversation.users
    Enum.each(users, &(send_reminders(shared_params, &1)))
    Enum.each(users, &(send_start(shared_params, &1, users, number, question)))
  end

  defp send_reminders(shared_params, user) do
    send_message(shared_params, S.reminders(), user)
  end

  defp send_start(shared_params, user, users, number, question) do
    partner_names = partner_names(user, users)
    message = S.iteration_start(partner_names, number, question)
    send_message(shared_params, message, user)
  end

  defp send_message(shared_params, text, user) do
    params = Map.merge(shared_params, %{recipient: user.phone, text: text})
    message = struct!(SMSMessage, params)

    @sender.send(message)
  end

  defp partner_names(user, users) do
    users
    |> Enum.reject(&(&1.id == user.id))
    |> Enum.map(&(&1.name))
  end
end
