defmodule Storage.Service.CommandHistory do
  @moduledoc false

  alias Storage.CommandHistory

  def insert(message) do
    params =
      %{text: message.text,
        timestamp: message.timestamp}
    changeset = CommandHistory.changeset(%CommandHistory{}, params)

    Storage.insert(changeset)
  end
end
