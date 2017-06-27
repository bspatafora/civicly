defmodule Core.Router do
  @moduledoc false

  alias Core.CommandParser

  @ben Application.get_env(:storage, :ben_phone)
  @sms_sender Application.get_env(:core, :sms_sender)
  @storage_service Application.get_env(:core, :storage_service)

  @spec handle(SMSMessage.t) :: no_return()
  def handle(message) do
    cond do
      command?(message) ->
        parse_command(message)
      stop?(message) ->
        delete_user(message)
        send_command_output("You have been deleted", message)
      true ->
        store(message)
        relay(message)
    end
  end

  defp command?(message) do
    message.sender == @ben && String.starts_with?(message.text, ":")
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

  defp stop?(message) do
    String.downcase(message.text) == "stop"
  end

  defp delete_user(message) do
    @storage_service.delete_user(message.sender)
  end

  defp store(message) do
    @storage_service.store_message(message)
  end

  defp relay(message) do
    partner_phones = @storage_service.partner_phones(message.sender)
    outbound_message = Map.put(message, :sender, message.recipient)

    partner_phones
    |> Enum.map(&(Map.put(outbound_message, :recipient, &1)))
    |> Enum.each(&(@sms_sender.send(&1)))
  end
end
