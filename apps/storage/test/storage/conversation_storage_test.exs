defmodule Storage.ConversationStorageTest do
  use ExUnit.Case

  alias Ecto.Adapters.SQL.Sandbox
  alias Ecto.DateTime
  alias Storage.{Conversation, User}

  setup do
    :ok = Sandbox.checkout(Storage)
    Sandbox.mode(Storage, {:shared, self()})
  end

  def changeset(params \\ %{}) do
    defaults =
      %{left_user_id: insert_user().id,
        right_user_id: insert_user().id,
        proxy_phone: "15555555555",
        start: to_string(DateTime.utc)}
    Conversation.changeset(%Conversation{}, Map.merge(defaults, params))
  end

  def insert_user do
    params = %{name: "Test User", phone: Helpers.random_phone}

    changeset = User.changeset(%User{}, params)
    {:ok, user} = Storage.insert(changeset)
    user
  end

  test "a conversation cannot have bogus parameters" do
    bogus_data = %{bogus: "data"}

    assert {:ok, conversation} = Storage.insert(changeset(bogus_data))

    refute Map.has_key?(conversation, :bogus)
  end

  test "a conversation's left user must exist" do
    nonexistent_left_user = %{left_user_id: 1_000_000}

    assert {:error, changeset} =
      Storage.insert(changeset(nonexistent_left_user))

    assert length(changeset.errors) == 1
    assert changeset.errors[:left_user_id] == {"does not exist", []}
  end

  test "a conversation's right user must exist" do
    nonexistent_right_user = %{right_user_id: 1_000_000}

    assert {:error, changeset} =
      Storage.insert(changeset(nonexistent_right_user))

    assert length(changeset.errors) == 1
    assert changeset.errors[:right_user_id] == {"does not exist", []}
  end

  test "a conversation is timestamped in UTC" do
    {:ok, conversation} = Storage.insert(changeset())

    assert conversation.inserted_at.time_zone == "Etc/UTC"
    assert conversation.updated_at.time_zone == "Etc/UTC"
  end

  test "a conversation's start time is stored in UTC" do
    {:ok, conversation} = Storage.insert(changeset())

    assert conversation.start.time_zone == "Etc/UTC"
  end

  test "a conversation cannot share any of its users with another conversation with the same start time" do
    time = to_string(DateTime.utc)
    {:ok, existing_conversation} = Storage.insert(changeset(%{start: time}))

    existing_users_and_time =
      %{left_user_id: existing_conversation.left_user_id,
        right_user_id: existing_conversation.right_user_id,
        start: time}
    {:error, changeset} =
      Storage.insert(changeset(existing_users_and_time))

    assert length(changeset.errors) == 1
    assert changeset.errors[:one_per_user_per_time] == {"violates an exclusion constraint", []}

    existing_reversed_users_and_time =
      %{left_user_id: existing_conversation.right_user_id,
        right_user_id: existing_conversation.left_user_id,
        start: time}
    {:error, changeset} =
      Storage.insert(changeset(existing_reversed_users_and_time))

    assert length(changeset.errors) == 1
    assert changeset.errors[:one_per_user_per_time] == {"violates an exclusion constraint", []}

    existing_right_user_and_time =
      %{left_user_id: insert_user().id,
        right_user_id: existing_conversation.right_user_id,
        start: time}
    {:error, changeset} =
      Storage.insert(changeset(existing_right_user_and_time))

    assert length(changeset.errors) == 1
    assert changeset.errors[:one_per_user_per_time] == {"violates an exclusion constraint", []}

    existing_reversed_right_user_and_time =
      %{left_user_id: insert_user().id,
        right_user_id: existing_conversation.left_user_id,
        start: time}
    {:error, changeset} =
      Storage.insert(changeset(existing_reversed_right_user_and_time))

    assert length(changeset.errors) == 1
    assert changeset.errors[:one_per_user_per_time] == {"violates an exclusion constraint", []}

    existing_left_user_and_time =
      %{left_user_id: existing_conversation.left_user_id,
        right_user_id: insert_user().id,
        start: time}
    {:error, changeset} =
      Storage.insert(changeset(existing_left_user_and_time))

    assert length(changeset.errors) == 1
    assert changeset.errors[:one_per_user_per_time] == {"violates an exclusion constraint", []}

    existing_reversed_left_user_and_time =
      %{left_user_id: existing_conversation.right_user_id,
        right_user_id: insert_user().id,
        start: time}
    {:error, changeset} =
      Storage.insert(changeset(existing_reversed_left_user_and_time))

    assert length(changeset.errors) == 1
    assert changeset.errors[:one_per_user_per_time] == {"violates an exclusion constraint", []}
  end

  test "a conversation can share users with another conversation with a different start time" do
    {:ok, existing_conversation} = Storage.insert(changeset(%{start: "2017-03-02 00:00:00"}))

    existing_users_but_different_time =
      %{left_user_id: existing_conversation.left_user_id,
        right_user_id: existing_conversation.right_user_id,
        start: "2017-03-06 00:00:00"}

    assert {:ok, _} =
      Storage.insert(changeset(existing_users_but_different_time))
  end

  # Constraint temporarily removed for testing
  #
  # test "a conversation must have two different users" do
  #   user = insert_user()
  #   same_user = %{left_user_id: user.id, right_user_id: user.id}

  #   {:error, changeset} = Storage.insert(changeset(same_user))

  #   assert length(changeset.errors) == 1
  #   assert changeset.errors[:different_user_ids] == {"is invalid", []}
  # end
end
