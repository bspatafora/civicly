defmodule Storage.UserSchemaTest do
  use ExUnit.Case, async: true

  alias Storage.User

  test "a valid user has a name and a phone number" do
    params = %{name: "Ben Spatafora", phone: "6306326718"}
    changeset = User.changeset(%User{}, params)

    assert changeset.valid?
  end

  test "a user with no name is invalid" do
    params = %{phone: "6306326718"}
    changeset = User.changeset(%User{}, params)

    assert length(changeset.errors) == 1
    assert changeset.errors[:name] == {"can't be blank", [validation: :required]}
  end

  test "a user with no phone is invalid" do
    params = %{name: "Ben Spatafora"}
    changeset = User.changeset(%User{}, params)

    assert length(changeset.errors) == 1
    assert changeset.errors[:phone] == {"can't be blank", [validation: :required]}
  end

  test "a user with too long a name is invalid" do
    params = %{name: String.duplicate("a", 101), phone: "6306326718"}
    changeset = User.changeset(%User{}, params)

    assert length(changeset.errors) == 1
    assert changeset.errors[:name] ==
      {"should be at most %{count} character(s)", [count: 100, validation: :length, max: 100]}
  end

  test "a user with a malformed phone number is invalid" do
    params = %{name: "Ben Spatafora", phone: "16306326718"}
    changeset = User.changeset(%User{}, params)

    assert length(changeset.errors) == 1
    assert changeset.errors[:phone] == {"has invalid format", [validation: :format]}
  end
end
