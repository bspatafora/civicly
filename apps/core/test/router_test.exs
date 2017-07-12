defmodule RouterTest do
  use ExUnit.Case, async: true

  @ben Application.get_env(:storage, :ben_phone)

  alias Core.Router
  alias Ecto.Adapters.SQL.Sandbox
  alias Plug.{Conn, Parsers}
  alias Storage.{Helpers, Message, Service, User}

  def parse_body_params(conn) do
    opts = Parsers.init([parsers: [:json], json_decoder: Poison])
    Parsers.call(conn, opts)
  end

  def build_message(params) do
    message = %SMSMessage{
      recipient: Helpers.random_phone(),
      sender: Helpers.random_phone(),
      sms_relay_ip: "localhost",
      text: "Test message",
      timestamp: DateTime.utc_now(),
      uuid: Helpers.uuid()}

    Map.merge(message, params)
  end

  setup do
    :ok = Sandbox.checkout(Storage)
    Sandbox.mode(Storage, {:shared, self()})

    bypass = Bypass.open(port: 9002)
    {:ok, bypass: bypass}
  end

  test "an inbound message is stored", %{bypass: bypass} do
    user = Helpers.insert_user()
    sms_relay = Helpers.insert_sms_relay(%{ip: "localhost"})
    conversation = Helpers.insert_conversation(%{
      sms_relay_id: sms_relay.id,
      users: [user.id, Helpers.insert_user().id]})
    text = "Test message"
    message = build_message(%{
      recipient: sms_relay.phone,
      sender: user.phone,
      text: text})

    Bypass.expect bypass, &(Conn.resp(&1, 200, ""))

    Router.handle(message)

    messages = Storage.all(Message)
    message = List.first(messages)
    assert length(messages) == 1
    assert message.conversation_id == conversation.id
    assert message.user_id == user.id
    assert message.text == text
    assert %DateTime{} = message.timestamp
  end

  test "an inbound message is relayed to all of the sender's partners", %{bypass: bypass} do
    user = Helpers.insert_user()
    partner1 = Helpers.insert_user()
    partner2 = Helpers.insert_user()
    sms_relay = Helpers.insert_sms_relay(%{ip: "localhost"})
    Helpers.insert_conversation(%{
      sms_relay_id: sms_relay.id,
      users: [user.id, partner1.id, partner2.id]})
    text = "Test message"
    message = build_message(%{
      recipient: sms_relay.phone,
      sender: user.phone,
      text: text})

    {:ok, recipients} = Agent.start_link(fn -> [] end)
    Bypass.expect bypass, fn conn ->
      conn = parse_body_params(conn)
      assert conn.params["text"] == text

      Agent.update(recipients, &([conn.params["recipient"] | &1]))

      Conn.resp(conn, 200, "")
    end

    Router.handle(message)

    partner_phones = [partner1.phone, partner2.phone]
    assert partner_phones -- Agent.get(recipients, &(&1)) == []
  end

  test "an add user command sent by Ben is parsed and executed", %{bypass: bypass} do
    Helpers.insert_sms_relay(%{ip: "localhost"})
    message = build_message(%{
      sender: @ben,
      text: ":add Test User 5555555555"})

    Bypass.expect bypass, &(Conn.resp(&1, 200, ""))

    Router.handle(message)

    users = Storage.all(User)
    user = List.first(users)
    assert length(users) == 1
    assert user.name == "Test User"
    assert user.phone == "5555555555"
  end

  test "an add user command that succeeds notifies", %{bypass: bypass} do
    Helpers.insert_sms_relay(%{ip: "localhost"})
    message = build_message(%{
      sender: @ben,
      text: ":add Test User 5555555555"})

    Bypass.expect bypass, fn conn ->
      conn = parse_body_params(conn)
      assert conn.params["recipient"] == @ben
      assert conn.params["text"] == "Added Test User"
      Conn.resp(conn, 200, "")
    end

    Router.handle(message)
  end

  test "an invalid add user command chides", %{bypass: bypass} do
    Helpers.insert_sms_relay(%{ip: "localhost"})
    message = build_message(%{
      sender: @ben,
      text: ":unknown Test User 5555555555"})

    Bypass.expect bypass, fn conn ->
      conn = parse_body_params(conn)
      assert conn.params["recipient"] == @ben
      assert conn.params["text"] == "Invalid command"
      Conn.resp(conn, 200, "")
    end

    Router.handle(message)

    assert length(Storage.all(User)) == 0
  end

  test "an add user command that fails notifies", %{bypass: bypass} do
    Helpers.insert_sms_relay(%{ip: "localhost"})
    message = build_message(%{
      sender: @ben,
      text: ":add Test User 555555555"})

    Bypass.expect bypass, fn conn ->
      conn = parse_body_params(conn)
      assert conn.params["recipient"] == @ben
      assert conn.params["text"] == "Insert failed"
      Conn.resp(conn, 200, "")
    end

    Router.handle(message)

    assert length(Storage.all(User)) == 0
  end

  test "a STOP message deletes the user", %{bypass: bypass} do
    user = Helpers.insert_user()
    partner = Helpers.insert_user()
    sms_relay = Helpers.insert_sms_relay(%{ip: "localhost"})
    Helpers.insert_conversation(%{
      sms_relay_id: sms_relay.id,
      users: [user.id, partner.id]})
    message = build_message(%{
      sender: user.phone,
      text: "STOP"})

    Bypass.expect bypass, &(Conn.resp(&1, 200, ""))

    Router.handle(message)

    assert Storage.get(User, user.id) == nil
  end

  test "a STOP message notifies the user and their partners", %{bypass: bypass} do
    user = Helpers.insert_user()
    partner1 = Helpers.insert_user()
    partner2 = Helpers.insert_user()
    sms_relay = Helpers.insert_sms_relay(%{ip: "localhost"})
    Helpers.insert_conversation(%{
      sms_relay_id: sms_relay.id,
      users: [user.id, partner1.id, partner2.id]})
    message = build_message(%{
      sender: user.phone,
      text: "STOP"})

    {:ok, messages} = Agent.start_link(fn -> [] end)
    Bypass.expect bypass, fn conn ->
      conn = parse_body_params(conn)
      recipient = conn.params["recipient"]
      text = conn.params["text"]
      Agent.update(messages, &([%{recipient: recipient, text: text} | &1]))
      Conn.resp(conn, 200, "")
    end

    Router.handle(message)

    messages = Agent.get(messages, &(&1))
    assert Enum.member?(messages, %{recipient: user.phone, text: "You have been deleted"})
    assert Enum.member?(messages, %{recipient: partner1.phone, text: "#{user.name} has quit"})
    assert Enum.member?(messages, %{recipient: partner2.phone, text: "#{user.name} has quit"})
  end

  test "if all of a user's partners have been deleted, an inbound message is relayed to no one" do
    user = Helpers.insert_user()
    partner = Helpers.insert_user()
    sms_relay = Helpers.insert_sms_relay(%{ip: "localhost"})
    Helpers.insert_conversation(%{
      sms_relay_id: sms_relay.id,
      users: [user.id, partner.id]})
    message = build_message(%{
      recipient: sms_relay.phone,
      sender: user.phone,
      text: "Test message"})

    Service.delete_user(partner.phone)

    # Will fail with a "Bypass got an HTTP request but wasn't
    # expecting one" error if any message is relayed
    Router.handle(message)
  end
end
