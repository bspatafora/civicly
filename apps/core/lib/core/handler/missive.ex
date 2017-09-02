defmodule Core.Handler.Missive do
  @moduledoc false

  alias Core.Sender
  alias Strings, as: S

  @storage Application.get_env(:core, :storage)

  def handle(message) do
    active_conversation? = @storage.active_conversation?(message.sender)

    if active_conversation? do
      partner_phones = @storage.partner_phones(message.sender)

      if Enum.any?(partner_phones) do
        store_and_relay(message, partner_phones)
      else
        send_empty_room(message)
      end
    else
      send_empty_room(message)
    end
  end

  defp store_and_relay(message, partner_phones) do
    @storage.store_message(message)

    Sender.send_message(message.text, partner_phones, message)
  end

  defp send_empty_room(message) do
    Sender.send_command_output(S.empty_room(), message)
  end
end
