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
end
