defmodule Storage.CommandHistoryTest do
  use ExUnit.Case

  alias Ecto.Adapters.SQL.Sandbox

  alias Storage.CommandHistory

  setup do
    :ok = Sandbox.checkout(Storage)
    Sandbox.mode(Storage, {:shared, self()})
  end

  def changeset(params \\ %{}) do
    defaults =
      %{text: "Test message",
        timestamp: DateTime.utc_now}

    CommandHistory.changeset(%CommandHistory{}, Map.merge(defaults, params))
  end

  test "a valid command history has text and a timestamp" do
    params =
      %{text: "Test message",
        timestamp: DateTime.utc_now}
    changeset = CommandHistory.changeset(%CommandHistory{}, params)

    assert changeset.valid?
  end

  test "a command history with no text is invalid" do
    params = %{timestamp: DateTime.utc_now}
    changeset = CommandHistory.changeset(%CommandHistory{}, params)

    assert length(changeset.errors) == 1
    assert changeset.errors[:text] == {"can't be blank", [validation: :required]}
  end

  test "a command history with no timestamp is invalid" do
    params = %{text: "Test message"}
    changeset = CommandHistory.changeset(%CommandHistory{}, params)

    assert length(changeset.errors) == 1
    assert changeset.errors[:timestamp] == {"can't be blank", [validation: :required]}
  end

  test "a command history cannot have bogus parameters" do
    changeset = changeset(%{bogus: "data"})

    assert {:ok, command_history} = Storage.insert(changeset)

    refute Map.has_key?(command_history, :bogus)
  end

  test "a command history is timestamped in UTC" do
    command_history = Storage.insert!(changeset())

    assert command_history.inserted_at.time_zone == "Etc/UTC"
    assert command_history.updated_at.time_zone == "Etc/UTC"
  end

  test "a command history's timestamp is stored in UTC" do
    command_history = Storage.insert!(changeset())

    assert command_history.timestamp.time_zone == "Etc/UTC"
  end

  test "a command history's text can be longer than 255 characters" do
    changeset = changeset(%{text: String.duplicate("a", 256)})

    assert {:ok, _} = Storage.insert(changeset)
  end
end
