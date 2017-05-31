defmodule Storage.UserStorageTest do
  use ExUnit.Case

  alias Ecto.Adapters.SQL.Sandbox
  alias Storage.{Helpers, User}

  setup do
    :ok = Sandbox.checkout(Storage)
    Sandbox.mode(Storage, {:shared, self()})
  end

  def changeset(params \\ %{}) do
    defaults = %{name: "Test User", phone: Helpers.random_phone}

    User.changeset(%User{}, Map.merge(defaults, params))
  end

  test "a user cannot have bogus parameters" do
    bogus_data = %{bogus: "data"}

    assert {:ok, user} = Storage.insert(changeset(bogus_data))

    refute Map.has_key?(user, :bogus)
  end

  test "a user's phone number must be unique" do
    duplicate_phone = %{phone: "5555555555"}
    Storage.insert!(changeset(duplicate_phone))

    assert {:error, changeset} = Storage.insert(changeset(duplicate_phone))

    assert length(changeset.errors) == 1
    assert changeset.errors[:phone] == {"has already been taken", []}
  end

  test "a user is timestamped in UTC" do
    {:ok, user} = Storage.insert(changeset())

    assert user.inserted_at.time_zone == "Etc/UTC"
    assert user.updated_at.time_zone == "Etc/UTC"
  end
end
