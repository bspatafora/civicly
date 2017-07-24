defmodule Storage.SMSRelayTest do
  use ExUnit.Case

  alias Ecto.Adapters.SQL.Sandbox

  alias Storage.{Helpers, SMSRelay}

  setup do
    :ok = Sandbox.checkout(Storage)
    Sandbox.mode(Storage, {:shared, self()})
  end

  defp changeset(params \\ %{}) do
    defaults =
      %{ip: "127.0.0.1",
        phone: Helpers.random_phone()}

    SMSRelay.changeset(%SMSRelay{}, Map.merge(defaults, params))
  end

  test "a valid SMS relay has an IP and a phone number" do
    params =
      %{ip: "127.0.0.1",
        phone: "5555555555"}
    changeset = SMSRelay.changeset(%SMSRelay{}, params)

    assert changeset.valid?
  end

  test "an SMS relay with no ip is invalid" do
    params = %{phone: "5555555555"}
    changeset = SMSRelay.changeset(%SMSRelay{}, params)

    assert length(changeset.errors) == 1
    assert changeset.errors[:ip] == {"can't be blank", [validation: :required]}
  end

  test "an SMS relay with no phone number is invalid" do
    params = %{ip: "127.0.0.1"}
    changeset = SMSRelay.changeset(%SMSRelay{}, params)

    assert length(changeset.errors) == 1
    assert changeset.errors[:phone] == {"can't be blank", [validation: :required]}
  end

  test "an SMS relay with a malformed phone number is invalid" do
    changeset = changeset(%{phone: "15555555555"})

    assert length(changeset.errors) == 1
    assert changeset.errors[:phone] == {"has invalid format", [validation: :format]}
  end

  test "an SMS relay cannot have bogus parameters" do
    changeset = changeset(%{bogus: "data"})

    assert {:ok, sms_relay} = Storage.insert(changeset)

    refute Map.has_key?(sms_relay, :bogus)
  end

  test "an SMS relay's phone number must be unique" do
    changeset = changeset(%{phone: "5555555555"})
    Storage.insert(changeset)

    {:error, changeset} = Storage.insert(changeset)

    assert length(changeset.errors) == 1
    assert changeset.errors[:phone] == {"has already been taken", []}
  end

  test "an SMS relay is timestamped in UTC" do
    {:ok, sms_relay} = Storage.insert(changeset())

    assert sms_relay.inserted_at.time_zone == "Etc/UTC"
    assert sms_relay.updated_at.time_zone == "Etc/UTC"
  end
end
