defmodule Iteration.Notifier do
  @moduledoc false

  alias Ecto.UUID

  alias Storage.Service.Conversation
  alias Strings, as: S

  @sender Application.get_env(:iteration, :sender)

  def notify(question) do
    conversations = Conversation.all_current()
    Enum.each(conversations, &(notify_users(&1, question)))
  end

  defp notify_users(conversation, question) do
    shared_params =
      %{sender: conversation.sms_relay.phone,
        sms_relay_ip: conversation.sms_relay.ip,
        timestamp: DateTime.utc_now(),
        uuid: UUID.generate()}
    users = conversation.users

    Enum.each(users, &(notify(shared_params, &1, users, question)))

    Conversation.activate(conversation)
  end

  defp notify(shared_params, user, users, question) do
    send_start(shared_params, user, users)
    send_question(shared_params, user, question)
  end

  defp send_start(shared_params, user, users) do
    partner_names = partner_names(user, users)
    message = S.iteration_start(partner_names)
    send_message(shared_params, message, user)
  end

  defp send_question(shared_params, user, question) do
    message = S.question(question)
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
