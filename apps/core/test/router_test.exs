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
    sender_phone = "5555555555"
    recipient_phone = "5555555556"
    proxy_phone = "5555555557"
    text = "Test message"

    sender = Helpers.insert_user(sender_phone)
    recipient = Helpers.insert_user(recipient_phone)
    sms_relay = Helpers.insert_sms_relay(%{ip: "localhost"})
    conversation = Helpers.insert_conversation(%{
      left_user_id: sender.id,
      right_user_id: recipient.id,
      sms_relay_id: sms_relay.id})

    Bypass.expect bypass, &(Conn.resp(&1, 200, ""))

    message = build_message(%{
      recipient: proxy_phone,
      sender: sender_phone,
      text: text})

    Router.handle(message)

    messages = Storage.all(Message)
    message = List.first(messages)
    assert length(messages) == 1
    assert message.conversation_id == conversation.id
    assert message.user_id == sender.id
    assert message.text == text
    assert %DateTime{} = message.timestamp
  end

  test "an inbound message is relayed to the sender's partner", %{bypass: bypass} do
    sender_phone = "5555555555"
    recipient_phone = "5555555556"
    proxy_phone = "5555555557"
    text = "Test message"

    sender = Helpers.insert_user(sender_phone)
    recipient = Helpers.insert_user(recipient_phone)
    sms_relay = Helpers.insert_sms_relay(%{ip: "localhost"})
    Helpers.insert_conversation(%{
      left_user_id: sender.id,
      right_user_id: recipient.id,
      sms_relay_id: sms_relay.id})

    Bypass.expect bypass, fn conn ->
      conn = parse_body_params(conn)

      assert conn.params["recipient"] == recipient_phone
      assert conn.params["text"] == text

      Conn.resp(conn, 200, "")
    end

    message = build_message(%{
      recipient: proxy_phone,
      sender: sender_phone,
      text: text})

    Router.handle(message)
  end

  test "partners can use different SMS relays", %{bypass: bypass} do
    sender_phone = "5555555555"
    recipient_phone = "5555555556"
    proxy_phone = "5555555557"
    text = "Test message"

    sender = Helpers.insert_user(sender_phone)
    recipient = Helpers.insert_user(recipient_phone)
    sms_relay = Helpers.insert_sms_relay(%{ip: "localhost"})
    Helpers.insert_conversation(%{
      left_user_id: sender.id,
      right_user_id: recipient.id,
      sms_relay_id: sms_relay.id})

    Bypass.expect bypass, fn conn ->
      conn = parse_body_params(conn)

      assert conn.params["recipient"] == recipient_phone
      assert conn.params["text"] == text

      Conn.resp(conn, 200, "")
    end

    message = build_message(%{
      recipient: proxy_phone,
      sender: sender_phone,
      sms_relay_ip: "not-localhost",
      text: text})

    Router.handle(message)
  end

  test "an add user command sent by Ben is parsed and executed", %{bypass: bypass} do
    Helpers.insert_sms_relay(%{ip: "localhost"})

    text = ":add Test User 5555555555"
    message = build_message(%{
      sender: @ben,
      sms_relay_ip: "not-localhost",
      text: text})

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

    text = ":add Test User 5555555555"
    message = build_message(%{
      sender: @ben,
      text: text})

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

    text = ":unknown Test User 5555555555"
    message = build_message(%{
      sender: @ben,
      text: text})

    Bypass.expect bypass, fn conn ->
      conn = parse_body_params(conn)

      assert conn.params["recipient"] == @ben
      assert conn.params["text"] == "Invalid command"

      Conn.resp(conn, 200, "")
    end

    Router.handle(message)

    users = Storage.all(User)
    assert length(users) == 0
  end

  test "an add user command that fails notifies", %{bypass: bypass} do
    Helpers.insert_sms_relay(%{ip: "localhost"})

    text = ":add Test User 555555555"
    message = build_message(%{
      sender: @ben,
      text: text})

    Bypass.expect bypass, fn conn ->
      conn = parse_body_params(conn)

      assert conn.params["recipient"] == @ben
      assert conn.params["text"] == "Insert failed"

      Conn.resp(conn, 200, "")
    end

    Router.handle(message)

    users = Storage.all(User)
    assert length(users) == 0
  end

  test "a STOP message deletes the user", %{bypass: bypass} do
    Helpers.insert_sms_relay(%{ip: "localhost"})

    {:ok, user} = Service.insert_user("Test User", "5555555555")

    message = build_message(%{
      sender: user.phone,
      text: "STOP"})

    Bypass.expect bypass, &(Conn.resp(&1, 200, ""))

    Router.handle(message)

    assert length(Storage.all(User)) == 0
  end

  test "a STOP message notifies the user", %{bypass: bypass} do
    Helpers.insert_sms_relay(%{ip: "localhost"})

    {:ok, user} = Service.insert_user("Test User", "5555555555")

    message = build_message(%{
      sender: user.phone,
      text: "STOP"})

    Bypass.expect bypass, fn conn ->
      conn = parse_body_params(conn)

      assert conn.params["recipient"] == user.phone
      assert conn.params["text"] == "You have been deleted"

      Conn.resp(conn, 200, "")
    end

    Router.handle(message)
  end
end
