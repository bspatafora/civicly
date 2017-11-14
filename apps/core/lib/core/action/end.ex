defmodule Core.Action.End do
  @moduledoc false

  alias Core.Sender
  alias Storage.Service.Conversation
  alias Strings, as: S

  def execute do
    Sender.send_to_active(S.iteration_end())
    Conversation.inactivate_all()
  end
end
