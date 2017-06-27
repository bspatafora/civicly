defmodule Storage.ConversationTest do
  use ExUnit.Case

  alias Ecto.Adapters.SQL.Sandbox
  alias Storage.{Conversation, Helpers}

  setup do
    :ok = Sandbox.checkout(Storage)
    Sandbox.mode(Storage, {:shared, self()})
  end

  defp changeset(params \\ %{}) do
    defaults = %{
      sms_relay_id: Helpers.insert_sms_relay().id,
      iteration: 1,
      users: [Helpers.insert_user().id, Helpers.insert_user().id]
    }

    Conversation.changeset(%Conversation{}, Map.merge(defaults, params))
  end

  test "a valid conversation has an SMS relay, an iteration, and at least two users" do
    params = %{
      sms_relay_id: Helpers.insert_sms_relay().id,
      iteration: 1,
      users: [Helpers.insert_user().id, Helpers.insert_user().id]
    }
    changeset = Conversation.changeset(%Conversation{}, params)

    assert {:ok, _} = Storage.insert(changeset)
  end

  test "a conversation with no SMS relay is invalid" do
    params = %{
      iteration: 1,
      users: [Helpers.insert_user().id, Helpers.insert_user().id]
    }
    changeset = Conversation.changeset(%Conversation{}, params)

    assert {:error, changeset} = Storage.insert(changeset)
    assert length(changeset.errors) == 1
    assert changeset.errors[:sms_relay_id] == {"can't be blank", [validation: :required]}
  end

  test "a conversation with no iteration is invalid" do
    params = %{
      sms_relay_id: Helpers.insert_sms_relay().id,
      users: [Helpers.insert_user().id, Helpers.insert_user().id]
    }
    changeset = Conversation.changeset(%Conversation{}, params)

    assert {:error, changeset} = Storage.insert(changeset)
    assert length(changeset.errors) == 1
    assert changeset.errors[:iteration] == {"can't be blank", [validation: :required]}
  end

  test "a conversation with no users is invalid" do
    params = %{
      sms_relay_id: Helpers.insert_sms_relay().id,
      iteration: 1
    }
    changeset = Conversation.changeset(%Conversation{}, params)

    assert {:error, changeset} = Storage.insert(changeset)
    assert length(changeset.errors) == 1
    assert changeset.errors[:users] ==
      {"should have at least %{count} item(s)", [count: 2, validation: :length, min: 2]}
  end

  test "a conversation with an iteration less than 1 is invalid" do
    changeset = changeset(%{iteration: 0})

    assert {:error, changeset} = Storage.insert(changeset)
    assert length(changeset.errors) == 1
    assert changeset.errors[:iteration] ==
      {"must be greater than %{number}", [validation: :number, number: 0]}
  end

  test "a conversation with only one user is invalid" do
    changeset = changeset(%{users: [Helpers.insert_user().id]})

    assert {:error, changeset} = Storage.insert(changeset)
    assert length(changeset.errors) == 1
    assert changeset.errors[:users] ==
      {"should have at least %{count} item(s)", [count: 2, validation: :length, min: 2]}
  end

  test "a conversation cannot have bogus parameters" do
    changeset = changeset(%{bogus: "data"})

    assert {:ok, conversation} = Storage.insert(changeset)

    refute Map.has_key?(conversation, :bogus)
  end

  test "a conversation's SMS relay must exist" do
    changeset = changeset(%{sms_relay_id: 1_000_000})

    assert {:error, changeset} = Storage.insert(changeset)
    assert length(changeset.errors) == 1
    assert changeset.errors[:sms_relay_id] == {"does not exist", []}
  end

  test "a conversation's users must exist" do
    changeset = changeset(%{users: [1_000_000, 1_000_001]})

    assert {:error, changeset} = Storage.insert(changeset)
    assert length(changeset.errors) == 1
    assert changeset.errors[:users] ==
      {"should have at least %{count} item(s)", [count: 2, validation: :length, min: 2]}
  end

  test "a conversation is timestamped in UTC" do
    {:ok, conversation} = Storage.insert(changeset())

    assert conversation.inserted_at.time_zone == "Etc/UTC"
    assert conversation.updated_at.time_zone == "Etc/UTC"
  end
end
