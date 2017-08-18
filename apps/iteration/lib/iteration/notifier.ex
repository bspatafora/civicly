defmodule Iteration.Notifier do
  @moduledoc false

  alias Ecto.UUID

  alias Strings, as: S

  @sender Application.get_env(:iteration, :sender)
  @storage Application.get_env(:iteration, :storage)

  def notify(question) do
    conversations = @storage.current_conversations()

    conversations |> Enum.each(&(notify_users(&1, question)))
  end

  defp notify_users(conversation, question) do
    shared_params =
      %{sender: conversation.sms_relay.phone,
        sms_relay_ip: conversation.sms_relay.ip,
        timestamp: DateTime.utc_now(),
        uuid: UUID.generate()}

    conversation.users
      |> Enum.each(&(send_message(shared_params, S.reminders(), &1)))

    conversation.users
      |> Enum.each(&(send_message(shared_params, S.iteration_start(question), &1)))
  end

  defp send_message(shared_params, text, user) do
    params = Map.merge(shared_params, %{recipient: user.phone, text: text})
    message = struct!(SMSMessage, params)

    @sender.send(message)
  end
end
