defmodule Core.Router do
  @moduledoc false

  @sms_sender Application.get_env(:core, :sms_sender)
  @storage_service Application.get_env(:core, :storage_service)

  @spec handle(SMSMessage.t) :: no_return()
  def handle(message) do
    store(message)
    relay(message)
  end

  defp store(message) do
    @storage_service.store_message(message)
  end

  defp relay(message) do
    {partner, proxy_phone} = @storage_service.current_partner_and_proxy_phones(message.sender)
    outbound_message = Map.merge(message, %{recipient: partner, sender: proxy_phone})

    @sms_sender.send(outbound_message)
  end
end
