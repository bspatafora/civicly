defmodule Core.Handler.MissiveTest do
  use ExUnit.Case

  alias Ecto.Adapters.SQL.Sandbox
  alias Plug.Conn

  alias Core.Handler.Missive
  alias Core.Helpers
  alias Storage.Helpers, as: StorageHelpers
  alias Storage.{Message, Service}

  setup do
    :ok = Sandbox.checkout(Storage)
    Sandbox.mode(Storage, {:shared, self()})

    bypass = Bypass.open(port: 9002)
    {:ok, bypass: bypass}
  end

  test "it stores a received missive", %{bypass: bypass} do
    user = StorageHelpers.insert_user()
    sms_relay = StorageHelpers.insert_sms_relay(%{ip: "localhost"})
    conversation = StorageHelpers.insert_conversation(%{
      sms_relay_id: sms_relay.id,
      users: [user.id, StorageHelpers.insert_user().id]})
    text = "Test message"
    message = Helpers.build_message(%{
      recipient: sms_relay.phone,
      sender: user.phone,
      text: text})

    Bypass.expect bypass, &(Conn.resp(&1, 200, ""))

    Missive.handle(message)

    message = List.first(Storage.all(Message))
    assert message.conversation_id == conversation.id
    assert message.user_id == user.id
    assert message.text == text
    assert %DateTime{} = message.timestamp
  end

  test "it relays a missive to the user's partners", %{bypass: bypass} do
    user = StorageHelpers.insert_user()
    partner1 = StorageHelpers.insert_user()
    partner2 = StorageHelpers.insert_user()
    sms_relay = StorageHelpers.insert_sms_relay(%{ip: "localhost"})
    StorageHelpers.insert_conversation(%{
      sms_relay_id: sms_relay.id,
      users: [user.id, partner1.id, partner2.id]})
    text = "Test message"
    message = Helpers.build_message(%{
      recipient: sms_relay.phone,
      sender: user.phone,
      text: text})

    {:ok, messages} = Helpers.MessageSpy.new()
    Bypass.expect bypass, fn conn ->
      conn = Helpers.parse_body_params(conn)
      Helpers.MessageSpy.record(messages, conn.params["recipient"], conn.params["text"])
      Conn.resp(conn, 200, "")
    end

    Missive.handle(message)

    messages = Helpers.MessageSpy.get(messages)
    assert length(messages) == 2
    assert Enum.member?(messages, %{recipient: partner1.phone, text: "#{user.name}: #{text}"})
    assert Enum.member?(messages, %{recipient: partner2.phone, text: "#{user.name}: #{text}"})
  end

  test "it relays a missive to no one if all of a user's partners have been deleted" do
    user = StorageHelpers.insert_user()
    partner = StorageHelpers.insert_user()
    sms_relay = StorageHelpers.insert_sms_relay(%{ip: "localhost"})
    StorageHelpers.insert_conversation(%{
      sms_relay_id: sms_relay.id,
      users: [user.id, partner.id]})
    message = Helpers.build_message(%{
      recipient: sms_relay.phone,
      sender: user.phone,
      text: "Test message"})

    Service.delete_user(partner.phone)

    # Will fail with a "Bypass got an HTTP request but wasn't
    # expecting one" error if any message is relayed
    Missive.handle(message)
  end
end
