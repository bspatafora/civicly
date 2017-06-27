defmodule Storage.UserTest do
  use ExUnit.Case

  alias Ecto.Adapters.SQL.Sandbox
  alias Storage.{Helpers, User}

  setup do
    :ok = Sandbox.checkout(Storage)
    Sandbox.mode(Storage, {:shared, self()})
  end

  def changeset(params \\ %{}) do
    defaults = %{name: "Test User", phone: Helpers.random_phone()}

    User.changeset(%User{}, Map.merge(defaults, params))
  end

  test "a valid user has a name and a phone number" do
    params = %{name: "Test User", phone: "5555555555"}
    changeset = User.changeset(%User{}, params)

    assert changeset.valid?
  end

  test "a user with no name is invalid" do
    params = %{phone: "5555555555"}
    changeset = User.changeset(%User{}, params)

    assert length(changeset.errors) == 1
    assert changeset.errors[:name] == {"can't be blank", [validation: :required]}
  end

  test "a user with no phone is invalid" do
    params = %{name: "Test User"}
    changeset = User.changeset(%User{}, params)

    assert length(changeset.errors) == 1
    assert changeset.errors[:phone] == {"can't be blank", [validation: :required]}
  end

  test "a user with too long a name is invalid" do
    changeset = changeset(%{name: String.duplicate("a", 101)})

    assert length(changeset.errors) == 1
    assert changeset.errors[:name] ==
      {"should be at most %{count} character(s)", [count: 100, validation: :length, max: 100]}
  end

  test "a user with a malformed phone number is invalid" do
    changeset = changeset(%{phone: "15555555555"})

    assert length(changeset.errors) == 1
    assert changeset.errors[:phone] == {"has invalid format", [validation: :format]}
  end

  test "a user cannot have bogus parameters" do
    changeset = changeset(%{bogus: "data"})

    assert {:ok, user} = Storage.insert(changeset)

    refute Map.has_key?(user, :bogus)
  end

  test "a user's phone number must be unique" do
    changeset = changeset(%{phone: "5555555555"})
    Storage.insert(changeset)

    assert {:error, changeset} = Storage.insert(changeset)

    assert length(changeset.errors) == 1
    assert changeset.errors[:phone] == {"has already been taken", []}
  end

  test "a user is timestamped in UTC" do
    {:ok, user} = Storage.insert(changeset())

    assert user.inserted_at.time_zone == "Etc/UTC"
    assert user.updated_at.time_zone == "Etc/UTC"
  end
end
