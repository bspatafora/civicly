defmodule Core.Router do
  @moduledoc false

  @sms_sender Application.get_env(:core, :sms_sender)
  @storage_service Application.get_env(:core, :storage_service)

  @spec handle(SMSMessage.t) :: no_return()
  def handle(message) do
    relay_to_partner(message)
  end

  defp relay_to_partner(message) do
    {recipient, proxy_phone} = fetch_recipient_and_proxy_phones(message.sender)
    outbound_message = %SMSMessage{
      recipient: recipient,
      sender: proxy_phone,
      text: message.text}

    @sms_sender.send(outbound_message)
  end

  defp fetch_recipient_and_proxy_phones(sender) do
    @storage_service.current_partner_and_proxy_phones(sender)
  end
end
