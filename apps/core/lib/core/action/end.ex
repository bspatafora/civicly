defmodule Core.Action.End do
  @moduledoc false

  alias Core.Sender
  alias Storage.Service
  alias Strings, as: S

  def execute do
    Sender.send_to_active(S.iteration_end())
    Service.inactivate_all_conversations()
  end
end
