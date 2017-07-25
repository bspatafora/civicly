defmodule Iteration.Notifier do
  @moduledoc false

  alias Ecto.UUID

  @sender Application.get_env(:iteration, :sender)
  @storage Application.get_env(:iteration, :storage)

  def notify do
    conversations = @storage.current_conversations()

    conversations |> Enum.each(&(notify_users(&1)))
  end

  defp notify_users(conversation) do
    shared_params =
      %{sender: conversation.sms_relay.phone,
        sms_relay_ip: conversation.sms_relay.ip,
        timestamp: DateTime.utc_now(),
        uuid: UUID.generate()}

    conversation.users
      |> Enum.map(&(build_message(shared_params, &1, conversation.users)))
      |> Enum.each(&(@sender.send(&1)))
  end

  defp build_message(shared_params, user, users) do
    text = "Say hello to #{partner_names(user, users)}!"
    params = Map.merge(shared_params, %{recipient: user.phone, text: text})

    struct!(SMSMessage, params)
  end

  defp partner_names(user, users) do
    users
      |> Enum.reject(&(&1.id == user.id))
      |> Enum.map(&(&1.name))
      |> Enum.join(" and ")
  end
end
