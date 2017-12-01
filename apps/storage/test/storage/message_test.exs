defmodule Storage.MessageTest do
  use ExUnit.Case

  alias Ecto.Adapters.SQL.Sandbox

  alias Storage.{Helpers, Message}

  setup do
    :ok = Sandbox.checkout(Storage)
    Sandbox.mode(Storage, {:shared, self()})
  end

  def changeset(params \\ %{}) do
    conversation = Helpers.insert_conversation()
    first_user_id = List.first(conversation.users).id

    defaults =
      %{conversation_id: conversation.id,
        user_id: first_user_id,
        text: "Test message",
        timestamp: DateTime.utc_now,
        uuid: Helpers.uuid()}

    Message.changeset(%Message{}, Map.merge(defaults, params))
  end

  test "a valid message has a conversation, a user, text, a timestamp, and a UUID" do
    params =
      %{conversation_id: 1,
        user_id: 1,
        text: "Test message",
        timestamp: DateTime.utc_now,
        uuid: Helpers.uuid()}
    changeset = Message.changeset(%Message{}, params)

    assert changeset.valid?
  end

  test "a message with no conversation_id is invalid" do
    params =
      %{user_id: 1,
        text: "Test message",
        timestamp: DateTime.utc_now,
        uuid: Helpers.uuid()}
    changeset = Message.changeset(%Message{}, params)

    assert length(changeset.errors) == 1
    assert changeset.errors[:conversation_id] == {"can't be blank", [validation: :required]}
  end

  test "a message with no user_id is invalid" do
    params =
      %{conversation_id: 1,
        text: "Test message",
        timestamp: DateTime.utc_now,
        uuid: Helpers.uuid()}
    changeset = Message.changeset(%Message{}, params)

    assert length(changeset.errors) == 1
    assert changeset.errors[:user_id] == {"can't be blank", [validation: :required]}
  end

  test "a message with no text is invalid" do
    params =
      %{conversation_id: 1,
        user_id: 1,
        timestamp: DateTime.utc_now,
        uuid: Helpers.uuid()}
    changeset = Message.changeset(%Message{}, params)

    assert length(changeset.errors) == 1
    assert changeset.errors[:text] == {"can't be blank", [validation: :required]}
  end

  test "a message with no timestamp is invalid" do
    params =
      %{conversation_id: 1,
        user_id: 1,
        text: "Test message",
        uuid: Helpers.uuid()}
    changeset = Message.changeset(%Message{}, params)

    assert length(changeset.errors) == 1
    assert changeset.errors[:timestamp] == {"can't be blank", [validation: :required]}
  end

  test "a message with no UUID is invalid" do
    params =
      %{conversation_id: 1,
        user_id: 1,
        text: "Test message",
        timestamp: DateTime.utc_now}
    changeset = Message.changeset(%Message{}, params)

    assert length(changeset.errors) == 1
    assert changeset.errors[:uuid] == {"can't be blank", [validation: :required]}
  end

  test "a message cannot have bogus parameters" do
    changeset = changeset(%{bogus: "data"})

    assert {:ok, message} = Storage.insert(changeset)

    refute Map.has_key?(message, :bogus)
  end

  test "a message's conversation must exist" do
    changeset = changeset(%{conversation_id: 1_000_000})

    assert {:error, changeset} = Storage.insert(changeset)

    assert length(changeset.errors) == 1
    assert changeset.errors[:conversation_id] == {"does not exist", []}
  end

  test "a message's user must exist" do
    changeset = changeset(%{user_id: 1_000_000})

    assert {:error, changeset} = Storage.insert(changeset)

    assert length(changeset.errors) == 1
    assert changeset.errors[:user_id] == {"does not exist", []}
  end

  test "a message is timestamped in UTC" do
    message = Storage.insert!(changeset())

    assert message.inserted_at.time_zone == "Etc/UTC"
    assert message.updated_at.time_zone == "Etc/UTC"
  end

  test "a message's timestamp is stored in UTC" do
    message = Storage.insert!(changeset())

    assert message.timestamp.time_zone == "Etc/UTC"
  end

  test "a message's text can be longer than 255 characters" do
    changeset = changeset(%{text: String.duplicate("a", 256)})

    assert {:ok, _} = Storage.insert(changeset)
  end
end
