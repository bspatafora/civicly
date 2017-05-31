defmodule RouterTest do
  use ExUnit.Case, async: true

  alias Core.Router
  alias Ecto.Adapters.SQL.Sandbox
  alias Plug.{Conn, Parsers}
  alias Storage.{Helpers, Message, User}

  def parse_body_params(conn) do
    opts = Parsers.init([parsers: [:json], json_decoder: Poison])
    Parsers.call(conn, opts)
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
    conversation = Helpers.insert_conversation(%{
      left_user_id: sender.id,
      right_user_id: recipient.id,
      proxy_phone: proxy_phone})

    Bypass.expect bypass, fn conn ->
      Conn.resp(conn, 200, "")
    end

    message = %SMSMessage{
      recipient: proxy_phone,
      sender: sender_phone,
      text: text,
      timestamp: DateTime.utc_now}

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
    Helpers.insert_conversation(%{
      left_user_id: sender.id,
      right_user_id: recipient.id,
      proxy_phone: proxy_phone})

    Bypass.expect bypass, fn conn ->
      conn = parse_body_params(conn)

      assert conn.params["recipient"] == recipient_phone
      assert conn.params["text"] == text

      Conn.resp(conn, 200, "")
    end

    message = %SMSMessage{
      recipient: proxy_phone,
      sender: sender_phone,
      text: text,
      timestamp: DateTime.utc_now}

    Router.handle(message)
  end

  test "an insert user command sent by Ben is parsed and executed" do
    sender = Application.get_env(:storage, :ben_phone)
    text = ":add Test User 5555555555"
    message = %SMSMessage{
      recipient: Helpers.random_phone,
      sender: sender,
      text: text,
      timestamp: DateTime.utc_now}

    Router.handle(message)

    users = Storage.all(User)
    user = List.first(users)
    assert length(users) == 1
    assert user.name == "Test User"
    assert user.phone == "5555555555"
  end
end
