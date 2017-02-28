defmodule Storage.RepoTest do
  use ExUnit.Case

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Storage)

    Ecto.Adapters.SQL.Sandbox.mode(Storage, {:shared, self()})
  end

  def create_user_changeset(params \\ %{}) do
    phone = Integer.to_string(Enum.random(5550000000..5559999999))
    defaults = %{name: "Test User", phone: phone}

    Storage.User.changeset(%Storage.User{}, Map.merge(defaults, params))
  end

  test "a user cannot have bogus parameters" do
    bogus_data = %{bogus: "data"}

    assert {:ok, user} = Storage.insert(create_user_changeset(bogus_data))

    refute Map.has_key?(user, :bogus)
  end

  test "a user's phone number must be unique" do
    duplicate_phone = %{phone: "5555555555"}
    Storage.insert!(create_user_changeset(duplicate_phone))

    assert {:error, changeset} = Storage.insert(create_user_changeset(duplicate_phone))

    assert length(changeset.errors) == 1
    assert changeset.errors[:phone] == {"has already been taken", []}
  end

  test "a user is timestamped" do
    {:ok, user} = Storage.insert(create_user_changeset())

    refute user.inserted_at == nil
    refute user.updated_at == nil
  end

  test "a user can have another user as a discussion partner" do
    {:ok, user1} = Storage.insert(create_user_changeset())
    {:ok, user2} = Storage.insert(create_user_changeset(%{partner_id: user1.id}))

    assert user2.partner_id == user1.id
  end

  test "a user's discussion partner must be unique" do
    {:ok, user1} = Storage.insert(create_user_changeset())
    {:ok, _} = Storage.insert(create_user_changeset(%{partner_id: user1.id}))

    assert {:error, changeset} = Storage.insert(create_user_changeset(%{partner_id: user1.id}))

    assert length(changeset.errors) == 1
    assert changeset.errors[:partner_id] == {"has already been taken", []}
  end

  test "a user's discussion partner must be an existing user" do
    nonexistent_partner = %{partner_id: 1}
    assert {:error, changeset} = Storage.insert(create_user_changeset(nonexistent_partner))

    assert length(changeset.errors) == 1
    assert changeset.errors[:partner_id] == {"does not exist", []}
  end

  test "when a user's discussion partner is deleted, the user's partner_id is nilified" do
    {:ok, user1} = Storage.insert(create_user_changeset())
    {:ok, user2} = Storage.insert(create_user_changeset(%{partner_id: user1.id}))

    assert user2.partner_id == user1.id

    Storage.delete!(user1)

    user2 = Storage.get!(Storage.User, user2.id)
    assert user2.partner_id == nil
  end
end
