defmodule Storage.RepoTest do
  use ExUnit.Case

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Storage)

    Ecto.Adapters.SQL.Sandbox.mode(Storage, {:shared, self()})
  end

  test "a user cannot have bogus parameters" do
    params = %{name: "Ben Spatafora", phone: "6306326718", bogus: "data"}
    changeset = Storage.User.changeset(%Storage.User{}, params)

    assert {:ok, user} = Storage.insert(changeset)
    refute Map.has_key?(user, :bogus)
  end

  test "a user's phone number must be unique" do
    params = %{name: "Ben Spatafora", phone: "6306326718"}
    changeset = Storage.User.changeset(%Storage.User{}, params)

    assert {:ok, _} = Storage.insert(changeset)

    {:error, changeset} = Storage.insert(changeset)

    assert changeset.valid? == false
    assert length(changeset.errors) == 1
    assert changeset.errors[:phone] == {"has already been taken", []}
  end

  test "a user is timestamped" do
    params = %{name: "Ben Spatafora", phone: "6306326718"}
    changeset = Storage.User.changeset(%Storage.User{}, params)

    assert {:ok, user} = Storage.insert(changeset)
    refute user.inserted_at == nil
    refute user.updated_at == nil
  end

  test "a user can have another user as a discussion partner" do
    params1 = %{name: "Ben Spatafora", phone: "6306326718"}
    changeset1 = Storage.User.changeset(%Storage.User{}, params1)

    assert {:ok, user1} = Storage.insert(changeset1)

    params2 = %{name: "John Walsh", phone: "5555555555", partner_id: user1.id}
    changeset2 = Storage.User.changeset(%Storage.User{}, params2)

    assert {:ok, user2} = Storage.insert(changeset2)

    assert user2.partner_id == user1.id
  end

  test "a user's discussion partner must be unique" do
    params1 = %{name: "Ben Spatafora", phone: "6306326718"}
    changeset1 = Storage.User.changeset(%Storage.User{}, params1)

    assert {:ok, user1} = Storage.insert(changeset1)

    params2 = %{name: "John Walsh", phone: "5555555555", partner_id: user1.id}
    changeset2 = Storage.User.changeset(%Storage.User{}, params2)

    assert {:ok, _} = Storage.insert(changeset2)

    params3 = %{name: "Abby Spatafora", phone: "5555555556", partner_id: user1.id}
    changeset3 = Storage.User.changeset(%Storage.User{}, params3)

    assert {:error, changeset} = Storage.insert(changeset3)

    assert changeset.valid? == false
    assert length(changeset.errors) == 1
    assert changeset.errors[:partner_id] == {"has already been taken", []}
  end

  test "a user's discussion partner must be an existing user" do
    params = %{name: "John Walsh", phone: "5555555555", partner_id: 1}
    changeset = Storage.User.changeset(%Storage.User{}, params)

    assert {:error, changeset} = Storage.insert(changeset)

    assert changeset.valid? == false
    assert length(changeset.errors) == 1
    assert changeset.errors[:partner_id] == {"does not exist", []}
  end

  test "when a user's discussion partner is deleted, the user's partner_id is nilified" do
    params1 = %{name: "Ben Spatafora", phone: "6306326718"}
    changeset1 = Storage.User.changeset(%Storage.User{}, params1)

    assert {:ok, user1} = Storage.insert(changeset1)

    params2 = %{name: "John Walsh", phone: "5555555555", partner_id: user1.id}
    changeset2 = Storage.User.changeset(%Storage.User{}, params2)

    assert {:ok, user2} = Storage.insert(changeset2)

    assert user2.partner_id == user1.id

    assert {:ok, _} = Storage.delete(user1)

    user2 = Storage.get!(Storage.User, user2.id)
    assert user2.partner_id == nil
  end
end
