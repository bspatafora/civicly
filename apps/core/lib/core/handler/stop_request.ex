defmodule Core.Handler.StopRequest do
  @moduledoc false

  alias Core.Sender

  @storage Application.get_env(:core, :storage)

  def handle(message) do
    partner_phones = @storage.partner_phones(message.sender)

    user = @storage.delete_user(message.sender)

    Sender.send_command_output("You have been deleted", message)
    Sender.send_message("#{user.name} has quit", partner_phones, message)
  end
end
