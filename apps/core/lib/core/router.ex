defmodule Core.Router do
  @moduledoc false

  @sms_sender Application.get_env(:core, :sms_sender)
  @storage_service Application.get_env(:core, :storage_service)

  @spec handle(SMSMessage.t) :: no_return()
  def handle(message) do
    store(message)
    relay_to_partner(message)
  end

  defp store(message) do
    @storage_service.store_message(message)
  end

  defp relay_to_partner(message) do
    {recipient, proxy_phone} = fetch_recipient_and_proxy_phones(message.sender)
    outbound_message = Map.merge(message, %{recipient: recipient, sender: proxy_phone})

    @sms_sender.send(outbound_message)
  end

  defp fetch_recipient_and_proxy_phones(sender) do
    @storage_service.current_partner_and_proxy_phones(sender)
  end
end
