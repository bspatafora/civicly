defmodule Core.Action.Reminder do
  @moduledoc false

  alias Core.Sender
  alias Storage.Service
  alias Strings, as: S

  def send do
    recipients = Service.not_yet_engaged_phones()
    Sender.send_message(S.conversation_reminder(), recipients)
  end
end
