defmodule Core.Handler.HelpRequest do
  @moduledoc false

  alias Core.Sender
  alias Strings, as: S

  def handle(message) do
    Sender.send_command_output(S.help(), message)
  end
end
