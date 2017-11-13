defmodule Core.Action.TimeWarning do
  @moduledoc false

  alias Core.Sender
  alias Strings, as: S

  def send do
    Sender.send_to_active(S.time_warning())
  end
end
