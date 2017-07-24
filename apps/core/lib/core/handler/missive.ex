defmodule Core.Handler.Missive do
  @moduledoc false

  alias Core.Sender

  @storage Application.get_env(:core, :storage)

  def handle(message) do
    @storage.store_message(message)

    partner_phones = @storage.partner_phones(message.sender)
    text = prepend_name_to_text(message)
    Sender.send_message(text, partner_phones, message)
  end

  defp prepend_name_to_text(message) do
    name = @storage.fetch_name(message.sender)
    "#{name}: #{message.text}"
  end
end
