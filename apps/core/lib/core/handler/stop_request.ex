defmodule Core.Handler.StopRequest do
  @moduledoc false

  alias Core.Sender
  alias Storage.Service
  alias Storage.Service.User
  alias Strings, as: S

  def handle(message) do
    sender = message.sender

    if Service.in_conversation?(sender) do
      partner_phones = Service.partner_phones(sender)

      inactivate_conversation(sender, partner_phones)
      user = delete_user(sender)

      send_partner_deletion(message, user.name, partner_phones)
      send_user_deletion(message)
    else
      delete_user(sender)

      send_user_deletion(message)
    end
  end

  defp delete_user(phone) do
    User.delete(phone)
  end

  defp inactivate_conversation(phone, partner_phones) do
    two_person_conversation? = length(partner_phones) == 1

    if two_person_conversation? do
      Service.inactivate_current_conversation(phone)
    end
  end

  defp send_partner_deletion(message, name, partner_phones) do
    text = S.partner_deletion(name)
    Sender.send_message(text, partner_phones, message)
  end

  defp send_user_deletion(message) do
    Sender.send_command_output(S.user_deletion(), message)
  end
end
