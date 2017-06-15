defmodule Core.Router do
  @moduledoc false

  alias Core.CommandParser
  alias Storage.Service

  @ben Application.get_env(:storage, :ben_phone)
  @sms_sender Application.get_env(:core, :sms_sender)
  @storage_service Application.get_env(:core, :storage_service)

  @spec handle(SMSMessage.t) :: no_return()
  def handle(message) do
    if message.sender == @ben && String.starts_with?(message.text, ":") do
      message = Service.refresh_sms_relay_ip(message)
      parse_command(message)
    else
      store(message)
      relay(message)
    end
  end

  defp parse_command(message) do
    case CommandParser.parse(message.text) do
      {:add, name, phone} ->
        add_user(name, phone, message)
      {:invalid} ->
        send_command_output("Invalid command", message)
    end
  end

  defp add_user(name, phone, message) do
    case @storage_service.insert_user(name, phone) do
      {:ok, user} ->
        send_command_output("Added #{user.name}", message)
      {:error, _} ->
        send_command_output("Insert failed", message)
    end
  end

  defp send_command_output(text, message) do
    output_params = %{
      recipient: message.sender,
      sender: message.recipient,
      text: text}
    output_message = Map.merge(message, output_params)

    @sms_sender.send(output_message)
  end

  defp store(message) do
    @storage_service.store_message(message)
  end

  defp relay(message) do
    {partner_phone, sms_relay_ip, sms_relay_phone} =
      @storage_service.current_conversation_details(message.sender)

    outbound_params = %{
      recipient: partner_phone,
      sender: sms_relay_phone,
      sms_relay_ip: sms_relay_ip}
    outbound_message = Map.merge(message, outbound_params)

    @sms_sender.send(outbound_message)
  end
end
