defmodule Storage.MessageSchemaTest do
  use ExUnit.Case, async: true

  alias Storage.{Helpers, Message}

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
end
