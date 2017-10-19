defmodule Core.Sender do
  @moduledoc false

  alias Ecto.UUID

  alias SMSMessage
  alias Storage.Service

  @sender Application.get_env(:core, :sender)

  def send_command_output(text, message) do
    send_message(text, [message.sender], message)
  end

  def send_to_all(text, message) do
    send_message(text, Service.all_phones(), message)
  end

  def send_to_active(text, message \\ internal_message()) do
    send_message(text, Service.active_phones(), message)
  end

  def send_message(text, recipients, message) do
    message = Map.merge(message, %{sender: message.recipient, text: text})

    recipients
    |> Enum.map(&(Map.put(message, :recipient, &1)))
    |> Enum.each(&(@sender.send(&1)))
  end

  defp internal_message do
    sms_relay = Service.first_sms_relay
    %SMSMessage{
      recipient: sms_relay.phone,
      sender: "",
      sms_relay_ip: sms_relay.ip,
      text: "",
      timestamp: DateTime.utc_now(),
      uuid: UUID.generate()}
  end
end
