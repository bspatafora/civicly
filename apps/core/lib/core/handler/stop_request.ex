defmodule Core.Handler.StopRequest do
  @moduledoc false

  alias Core.Sender
  alias Strings, as: S

  @storage Application.get_env(:core, :storage)

  def handle(message) do
    if @storage.active_conversation?(message.sender) do
      partner_phones = @storage.partner_phones(message.sender)

      user = delete_user(message.sender)

      send_partner_deletion(message, user.name, partner_phones)
      send_user_deletion(message)
    else
      delete_user(message.sender)

      send_user_deletion(message)
    end
  end

  defp delete_user(phone) do
    @storage.delete_user(phone)
  end

  defp send_partner_deletion(message, name, partner_phones) do
    text = S.partner_deletion(name)
    Sender.send_message(text, partner_phones, message)
  end

  defp send_user_deletion(message) do
    Sender.send_command_output(S.user_deletion(), message)
  end
end
