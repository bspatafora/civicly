defmodule Core.Handler.MissiveTest do
  use ExUnit.Case

  alias Ecto.Adapters.SQL.Sandbox
  alias Plug.Conn

  alias Core.Handler.Missive
  alias Core.Helpers
  alias Core.Helpers.MessageSpy
  alias Storage.Helpers, as: StorageHelpers
  alias Storage.Message
  alias Strings, as: S

  setup do
    :ok = Sandbox.checkout(Storage)
    Sandbox.mode(Storage, {:shared, self()})

    bypass = Bypass.open(port: 9002)
    {:ok, bypass: bypass}
  end

  test "it stores a received missive", %{bypass: bypass} do
    sms_relay = StorageHelpers.insert_sms_relay(%{ip: "localhost"})
    user = StorageHelpers.insert_user()
    conversation = StorageHelpers.insert_conversation(%{
      active?: true,
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
    sms_relay = StorageHelpers.insert_sms_relay(%{ip: "localhost"})
    user = StorageHelpers.insert_user()
    partner1 = StorageHelpers.insert_user()
    partner2 = StorageHelpers.insert_user()
    StorageHelpers.insert_conversation(%{
      active?: true,
      sms_relay_id: sms_relay.id,
      users: [user.id, partner1.id, partner2.id]})
    text = "Test message"
    message = Helpers.build_message(%{
      recipient: sms_relay.phone,
      sender: user.phone,
      text: text})

    {:ok, messages} = MessageSpy.new()
    Bypass.expect bypass, fn conn ->
      conn = Helpers.parse_body_params(conn)
      MessageSpy.record(messages, conn.params["recipient"], conn.params["text"])
      Conn.resp(conn, 200, "")
    end

    Missive.handle(message)

    messages = MessageSpy.get(messages)
    assert length(messages) == 2
    assert Enum.member?(messages, %{recipient: partner1.phone, text: text})
    assert Enum.member?(messages, %{recipient: partner2.phone, text: text})
  end

  test "it responds with a no partners message when the user is not in an active conversation", %{bypass: bypass} do
    sms_relay = StorageHelpers.insert_sms_relay(%{ip: "localhost"})
    user = StorageHelpers.insert_user()
    partner1 = StorageHelpers.insert_user()
    partner2 = StorageHelpers.insert_user()
    StorageHelpers.insert_conversation(%{
      active?: false,
      sms_relay_id: sms_relay.id,
      users: [user.id, partner1.id, partner2.id]})
    message = Helpers.build_message(%{
      recipient: sms_relay.phone,
      sender: user.phone,
      text: "Test message"})

    Bypass.expect bypass, fn conn ->
      conn = Helpers.parse_body_params(conn)
      assert conn.params["recipient"] == user.phone
      assert conn.params["text"] == S.no_partners()
      Conn.resp(conn, 200, "")
    end

    Missive.handle(message)
  end

  test "it responds with a no partners message when the user has no conversations", %{bypass: bypass} do
    sms_relay = StorageHelpers.insert_sms_relay(%{ip: "localhost"})
    user = StorageHelpers.insert_user()
    message = Helpers.build_message(%{
      recipient: sms_relay.phone,
      sender: user.phone,
      text: "Test message"})

    Bypass.expect bypass, fn conn ->
      conn = Helpers.parse_body_params(conn)
      assert conn.params["recipient"] == user.phone
      assert conn.params["text"] == S.no_partners()
      Conn.resp(conn, 200, "")
    end

    Missive.handle(message)
  end

  test "it responds with a no partners message when all of the user's partners have been deleted", %{bypass: bypass} do
    sms_relay = StorageHelpers.insert_sms_relay(%{ip: "localhost"})
    user = StorageHelpers.insert_user()
    partner = StorageHelpers.insert_user()
    StorageHelpers.insert_conversation(%{
      active?: true,
      sms_relay_id: sms_relay.id,
      users: [user.id, partner.id]})
    message = Helpers.build_message(%{
      recipient: sms_relay.phone,
      sender: user.phone,
      text: "Test message"})

    Bypass.expect bypass, fn conn ->
      conn = Helpers.parse_body_params(conn)
      assert conn.params["recipient"] == user.phone
      assert conn.params["text"] == S.no_partners()
      Conn.resp(conn, 200, "")
    end

    Storage.delete!(partner)

    Missive.handle(message)
  end
end
