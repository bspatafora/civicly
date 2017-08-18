defmodule Core.Handler.StopRequest do
  @moduledoc false

  alias Core.Sender
  alias Strings, as: S

  @storage Application.get_env(:core, :storage)

  def handle(message) do
    partner_phones = @storage.partner_phones(message.sender)

    user = @storage.delete_user(message.sender)

    Sender.send_command_output(S.user_deletion(), message)
    Sender.send_message(S.partner_deletion(user.name), partner_phones, message)
  end
end
