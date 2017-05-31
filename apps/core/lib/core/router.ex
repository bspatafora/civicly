defmodule Core.Router do
  @moduledoc false

  @ben Application.get_env(:storage, :ben_phone)
  @sms_sender Application.get_env(:core, :sms_sender)
  @storage_service Application.get_env(:core, :storage_service)

  @spec handle(SMSMessage.t) :: no_return()
  def handle(message) do
    cond do
      message.sender == @ben && String.starts_with?(message.text, ":") ->
        parse_command(message)
      true ->
        store(message)
        relay(message)
    end
  end

  defp parse_command(message) do
    [command | rest] = String.split(message.text, " ", parts: 2)
    data = List.first(rest)

    cond do
      command == ":add" ->
        {name, phone} = String.split_at(data, -10)
        name = String.trim_trailing(name)
        @storage_service.insert_user(name, phone)
    end
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
