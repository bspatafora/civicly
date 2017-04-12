defmodule Storage.MessageStorageTest do
  use ExUnit.Case

  alias Ecto.Adapters.SQL.Sandbox
  alias Storage.{Conversation, Message, User}

  setup do
    :ok = Sandbox.checkout(Storage)
    Sandbox.mode(Storage, {:shared, self()})
  end

  def changeset(params \\ %{}) do
    conversation = insert_conversation()
    defaults =
      %{conversation_id: conversation.id,
        user_id: conversation.left_user_id,
        text: "Test message",
        timestamp: DateTime.utc_now}

    Message.changeset(%Message{}, Map.merge(defaults, params))
  end

  def insert_conversation do
    params =
      %{left_user_id: insert_user().id,
        right_user_id: insert_user().id,
        proxy_phone: "15555555555",
        start: DateTime.utc_now}

    changeset = Conversation.changeset(%Conversation{}, params)
    {:ok, conversation} = Storage.insert(changeset)
    conversation
  end

  def insert_user do
    params = %{name: "Test User", phone: Helpers.random_phone}

    changeset = User.changeset(%User{}, params)
    {:ok, user} = Storage.insert(changeset)
    user
  end

  test "a message cannot have bogus parameters" do
    bogus_data = %{bogus: "data"}

    assert {:ok, message} = Storage.insert(changeset(bogus_data))

    refute Map.has_key?(message, :bogus)
  end

  test "a message's conversation must exist" do
    nonexistent_conversation = %{conversation_id: 1_000_000}

    assert {:error, changeset} =
      Storage.insert(changeset(nonexistent_conversation))

    assert length(changeset.errors) == 1
    assert changeset.errors[:conversation_id] == {"does not exist", []}
  end

  test "a message's user must exist" do
    nonexistent_user = %{user_id: 1_000_000}

    assert {:error, changeset} =
      Storage.insert(changeset(nonexistent_user))

    assert length(changeset.errors) == 1
    assert changeset.errors[:user_id] == {"does not exist", []}
  end

  test "a message is timestamped in UTC" do
    {:ok, message} = Storage.insert(changeset())

    assert message.inserted_at.time_zone == "Etc/UTC"
    assert message.updated_at.time_zone == "Etc/UTC"
  end

  test "a message's timestamp is stored in UTC" do
    {:ok, message} = Storage.insert(changeset())

    assert message.timestamp.time_zone == "Etc/UTC"
  end
end
