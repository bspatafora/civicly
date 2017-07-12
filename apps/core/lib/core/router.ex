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
        handle_command(message)
      stop?(message) ->
        delete_user(message)
      true ->
        store(message)
        relay(message)
    end
  end

  defp command?(message) do
    message.sender == @ben && String.starts_with?(message.text, ":")
  end

  defp handle_command(message) do
    case CommandParser.parse(message.text) do
      {:add, name, phone} ->
        attempt_user_insert(name, phone, message)
      {:invalid} ->
        send_command_output("Invalid command", message)
    end
  end

  defp attempt_user_insert(name, phone, message) do
    case @storage_service.insert_user(name, phone) do
      {:ok, user} ->
        send_command_output("Added #{user.name}", message)
      {:error, _} ->
        send_command_output("Insert failed", message)
    end
  end

  defp stop?(message) do
    String.downcase(message.text) == "stop"
  end

  defp delete_user(message) do
    partner_phones = @storage_service.partner_phones(message.sender)
    user = @storage_service.delete_user(message.sender)
    send_command_output("You have been deleted", message)
    send_sms("#{user.name} has quit", partner_phones, message)
  end

  defp store(message) do
    @storage_service.store_message(message)
  end

  defp send_command_output(text, message) do
    send_sms(text, [message.sender], message)
  end

  defp relay(message) do
    partner_phones = @storage_service.partner_phones(message.sender)
    text = prepend_name_to_text(message)
    send_sms(text, partner_phones, message)
  end

  defp prepend_name_to_text(message) do
    name = @storage_service.fetch_name(message.sender)
    "#{name}: #{message.text}"
  end

  defp send_sms(text, recipients, message) do
    message = Map.merge(message, %{sender: message.recipient, text: text})

    recipients
    |> Enum.map(&(Map.put(message, :recipient, &1)))
    |> Enum.each(&(@sms_sender.send(&1)))
  end
end
