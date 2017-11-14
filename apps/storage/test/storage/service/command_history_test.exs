defmodule Storage.Service.CommandHistoryTest do
  use ExUnit.Case

  alias Ecto.Adapters.SQL.Sandbox

  alias Storage.{CommandHistory, Helpers}
  alias Storage.Service.CommandHistory, as: CommandHistoryService

  setup do
    :ok = Sandbox.checkout(Storage)
    Sandbox.mode(Storage, {:shared, self()})
  end

  test "insert/1 inserts a command history entry" do
    message = Helpers.build_message()

    CommandHistoryService.insert(message)

    command_history = List.first(Storage.all(CommandHistory))
    assert command_history.text == message.text
    assert command_history.timestamp == message.timestamp
  end
end
