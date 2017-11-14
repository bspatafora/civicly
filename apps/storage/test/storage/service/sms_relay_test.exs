defmodule Storage.Service.SMSRelayTest do
  use ExUnit.Case

  alias Ecto.Adapters.SQL.Sandbox

  alias Storage.Helpers
  alias Storage.Service.SMSRelay, as: SMSRelayService

  setup do
    :ok = Sandbox.checkout(Storage)
    Sandbox.mode(Storage, {:shared, self()})
  end

  test "update_ip/1 updates the IP of the first SMS relay" do
    Helpers.insert_sms_relay(%{ip: "127.0.0.1"})
    Helpers.insert_sms_relay(%{ip: "localhost"})

    SMSRelayService.update_ip("127.0.0.2")

    assert Helpers.first_sms_relay_ip() == "127.0.0.2"
  end

  test "get/0 returns the first SMS relay" do
    first_sms_relay = Helpers.insert_sms_relay()
    Helpers.insert_sms_relay()

    assert SMSRelayService.get() == first_sms_relay
  end
end
