defmodule Storage.ConversationSchemaTest do
  use ExUnit.Case, async: true

  test "a valid conversation has two users, a proxy phone number, and a start time" do
    params =
      %{left_user_id: 1,
        right_user_id: 2,
        proxy_phone: "15555555555",
        start: "2017-03-01 00:00:00"}
    changeset = Storage.Conversation.changeset(%Storage.Conversation{}, params)

    assert changeset.valid?
  end

  test "a conversation with no left user is invalid" do
    params =
      %{right_user_id: 2,
        proxy_phone: "15555555555",
        start: "2017-03-01 00:00:00"}
    changeset = Storage.Conversation.changeset(%Storage.Conversation{}, params)

    assert length(changeset.errors) == 1
    assert changeset.errors[:left_user_id] == {"can't be blank", [validation: :required]}
  end

  test "a conversation with no right user is invalid" do
    params =
      %{left_user_id: 1,
        proxy_phone: "15555555555",
        start: "2017-03-01 00:00:00"}
    changeset = Storage.Conversation.changeset(%Storage.Conversation{}, params)

    assert length(changeset.errors) == 1
    assert changeset.errors[:right_user_id] == {"can't be blank", [validation: :required]}
  end

  test "a conversation with no proxy phone number is invalid" do
    params =
      %{left_user_id: 1,
        right_user_id: 2,
        start: "2017-03-01 00:00:00"}
    changeset = Storage.Conversation.changeset(%Storage.Conversation{}, params)

    assert length(changeset.errors) == 1
    assert changeset.errors[:proxy_phone] == {"can't be blank", [validation: :required]}
  end

  test "a conversation with no start time is invalid" do
    params =
      %{left_user_id: 1,
        right_user_id: 2,
        proxy_phone: "15555555555"}
    changeset = Storage.Conversation.changeset(%Storage.Conversation{}, params)

    assert length(changeset.errors) == 1
    assert changeset.errors[:start] == {"can't be blank", [validation: :required]}
  end

  test "a conversation with a malformed proxy phone number is invalid" do
    params =
      %{left_user_id: 1,
        right_user_id: 2,
        proxy_phone: "5555555555",
        start: "2017-03-01 00:00:00"}
    changeset = Storage.Conversation.changeset(%Storage.Conversation{}, params)

    assert length(changeset.errors) == 1
    assert changeset.errors[:proxy_phone] == {"has invalid format", [validation: :format]}
  end
end
