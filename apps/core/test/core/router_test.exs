defmodule Core.RouterTest do
  use ExUnit.Case

  alias Ecto.Adapters.SQL.Sandbox
  alias Plug.Conn

  alias Core.{Helpers, Router}
  alias Storage.Helpers, as: StorageHelpers
  alias Storage.{Message, User}

  @ben Application.get_env(:storage, :ben_phone)

  setup do
    :ok = Sandbox.checkout(Storage)
    Sandbox.mode(Storage, {:shared, self()})

    bypass = Bypass.open(port: 9002)
    {:ok, bypass: bypass}
  end

  test "it routes a command", %{bypass: bypass} do
    StorageHelpers.insert_sms_relay(%{ip: "localhost"})
    message = Helpers.build_message(%{
      sender: @ben,
      text: ":add Test User 5555555555"})

    Bypass.expect bypass, &(Conn.resp(&1, 200, ""))

    Router.handle(message)

    assert length(Storage.all(User)) == 1
  end

  test "it routes a STOP request", %{bypass: bypass} do
    user = StorageHelpers.insert_user()
    partner = StorageHelpers.insert_user()
    sms_relay = StorageHelpers.insert_sms_relay(%{ip: "localhost"})
    StorageHelpers.insert_conversation(%{
      sms_relay_id: sms_relay.id,
      users: [user.id, partner.id]})
    message = Helpers.build_message(%{
      sender: user.phone,
      text: "STOP"})

    Bypass.expect bypass, &(Conn.resp(&1, 200, ""))

    Router.handle(message)

    assert Storage.get(User, user.id) == nil
  end

  test "it routes a missive", %{bypass: bypass} do
    user = StorageHelpers.insert_user()
    sms_relay = StorageHelpers.insert_sms_relay(%{ip: "localhost"})
    StorageHelpers.insert_conversation(%{
      sms_relay_id: sms_relay.id,
      users: [user.id, StorageHelpers.insert_user().id]})
    text = "Test message"
    message = Helpers.build_message(%{
      recipient: sms_relay.phone,
      sender: user.phone,
      text: text})

    Bypass.expect bypass, &(Conn.resp(&1, 200, ""))

    Router.handle(message)

    assert length(Storage.all(Message)) == 1
  end
end
