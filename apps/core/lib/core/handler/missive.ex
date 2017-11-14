defmodule Core.Handler.Missive do
  @moduledoc false

  alias Core.Sender
  alias Storage.Service
  alias Strings, as: S

  def handle(message) do
    in_conversation? = Service.in_conversation?(message.sender)

    if in_conversation? do
      partner_phones = Service.partner_phones(message.sender)

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
    Service.store_message(message)

    Sender.send_message(message.text, partner_phones, message)
  end

  defp send_empty_room(message) do
    Sender.send_command_output(S.empty_room(), message)
  end
end
