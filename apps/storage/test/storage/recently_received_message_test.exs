defmodule Storage.RecentlyReceivedMessageTest do
  use ExUnit.Case

  alias Ecto.Adapters.SQL.Sandbox

  alias Storage.{Helpers, RecentlyReceivedMessage}

  setup do
    :ok = Sandbox.checkout(Storage)
    Sandbox.mode(Storage, {:shared, self()})
  end

  def changeset(params \\ %{}) do
    defaults =
      %{sender: Helpers.random_phone(),
        text: "Test message",
        timestamp: DateTime.utc_now()}

    params = Map.merge(defaults, params)
    RecentlyReceivedMessage.changeset(%RecentlyReceivedMessage{}, params)
  end

  test "a valid recently received message has a sender, text, and timestamp" do
    params =
      %{sender: "5555555555",
        text: "Test message",
        timestamp: DateTime.utc_now()}
    changeset = RecentlyReceivedMessage.changeset(%RecentlyReceivedMessage{}, params)

    assert changeset.valid?
  end

  test "a recently received message with no sender is invalid" do
    params =
      %{text: "Test message",
        timestamp: DateTime.utc_now()}
    changeset = RecentlyReceivedMessage.changeset(%RecentlyReceivedMessage{}, params)

    assert length(changeset.errors) == 1
    assert changeset.errors[:sender] == {"can't be blank", [validation: :required]}
  end

  test "a recently received message with no text is invalid" do
    params =
      %{sender: "5555555555",
        timestamp: DateTime.utc_now()}
    changeset = RecentlyReceivedMessage.changeset(%RecentlyReceivedMessage{}, params)

    assert length(changeset.errors) == 1
    assert changeset.errors[:text] == {"can't be blank", [validation: :required]}
  end

  test "a recently received message with no timestamp is invalid" do
    params =
      %{sender: "5555555555",
        text: "Test message"}
    changeset = RecentlyReceivedMessage.changeset(%RecentlyReceivedMessage{}, params)

    assert length(changeset.errors) == 1
    assert changeset.errors[:timestamp] == {"can't be blank", [validation: :required]}
  end

  test "a recently received message cannot have bogus parameters" do
    changeset = changeset(%{bogus: "data"})

    assert {:ok, recently_received_message} = Storage.insert(changeset)

    refute Map.has_key?(recently_received_message, :bogus)
  end

  test "a recently received message is timestamped in UTC" do
    recently_received_message = Storage.insert!(changeset())

    assert recently_received_message.inserted_at.time_zone == "Etc/UTC"
    assert recently_received_message.updated_at.time_zone == "Etc/UTC"
  end

  test "a recently received message's timestamp is stored in UTC" do
    recently_received_message = Storage.insert!(changeset())

    assert recently_received_message.timestamp.time_zone == "Etc/UTC"
  end

  test "a recently received message's text can be longer than 255 characters" do
    changeset = changeset(%{text: String.duplicate("a", 256)})

    assert {:ok, _} = Storage.insert(changeset)
  end
end
