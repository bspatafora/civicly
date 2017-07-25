defmodule Core.Sender do
  @moduledoc false

  @sender Application.get_env(:core, :sender)

  def send_command_output(text, message) do
    send_message(text, [message.sender], message)
  end

  def send_message(text, recipients, message) do
    message = Map.merge(message, %{sender: message.recipient, text: text})

    recipients
    |> Enum.map(&(Map.put(message, :recipient, &1)))
    |> Enum.each(&(@sender.send(&1)))
  end
end