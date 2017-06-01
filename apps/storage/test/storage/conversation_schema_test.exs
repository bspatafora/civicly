defmodule Storage.ConversationSchemaTest do
  use ExUnit.Case, async: true

  alias Storage.Conversation

  test "a valid conversation has two users, an SMS relay, and a start time" do
    params =
      %{left_user_id: 1,
        right_user_id: 2,
        sms_relay_id: 1,
        start: DateTime.utc_now}
    changeset = Conversation.changeset(%Conversation{}, params)

    assert changeset.valid?
  end

  test "a conversation with no left user is invalid" do
    params =
      %{right_user_id: 2,
        sms_relay_id: 1,
        start: DateTime.utc_now}
    changeset = Conversation.changeset(%Conversation{}, params)

    assert length(changeset.errors) == 1
    assert changeset.errors[:left_user_id] == {"can't be blank", [validation: :required]}
  end

  test "a conversation with no right user is invalid" do
    params =
      %{left_user_id: 1,
        sms_relay_id: 1,
        start: DateTime.utc_now}
    changeset = Conversation.changeset(%Conversation{}, params)

    assert length(changeset.errors) == 1
    assert changeset.errors[:right_user_id] == {"can't be blank", [validation: :required]}
  end

  test "a conversation with no SMS relay is invalid" do
    params =
      %{left_user_id: 1,
        right_user_id: 2,
        start: DateTime.utc_now}
    changeset = Conversation.changeset(%Conversation{}, params)

    assert length(changeset.errors) == 1
    assert changeset.errors[:sms_relay_id] == {"can't be blank", [validation: :required]}
  end

  test "a conversation with no start time is invalid" do
    params =
      %{left_user_id: 1,
        right_user_id: 2,
        sms_relay_id: 1}
    changeset = Conversation.changeset(%Conversation{}, params)

    assert length(changeset.errors) == 1
    assert changeset.errors[:start] == {"can't be blank", [validation: :required]}
  end
end
