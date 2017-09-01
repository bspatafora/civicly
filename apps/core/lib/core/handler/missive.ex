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
        send_no_partners(message)
      end
    else
      send_no_partners(message)
    end
  end

  defp store_and_relay(message, partner_phones) do
    @storage.store_message(message)

    text = prepend_name_to_text(message)
    Sender.send_message(text, partner_phones, message)
  end

  defp send_no_partners(message) do
    Sender.send_command_output(S.no_partners(), message)
  end

  defp prepend_name_to_text(message) do
    name = @storage.name(message.sender)
    S.prepend_name(name, message.text)
  end
end
