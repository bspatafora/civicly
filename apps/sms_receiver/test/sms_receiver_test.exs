defmodule SMSReceiverTest do
  use ExUnit.Case
  use Plug.Test

  alias Ecto.Adapters.SQL.Sandbox
  alias Plug.{Conn, Parsers}
  alias Storage.{Conversation, Message, User}

  def insert_conversation(left_user, right_user, proxy_phone) do
    params = %{
      left_user_id: left_user.id,
      right_user_id: right_user.id,
      proxy_phone: proxy_phone,
      start: to_string(DateTime.utc_now)}
    changeset = Conversation.changeset(%Conversation{}, params)

    {:ok, conversation} = Storage.insert(changeset)
    conversation
  end

  def insert_user(phone) do
    params = %{name: "Test User", phone: phone}
    changeset = User.changeset(%User{}, params)

    {:ok, user} = Storage.insert(changeset)
    user
  end

  def parse_body_params(conn) do
    opts = Parsers.init([parsers: [Parsers.URLENCODED]])
    Parsers.call(conn, opts)
  end

  setup do
    :ok = Sandbox.checkout(Storage)
    Sandbox.mode(Storage, {:shared, self()})

    bypass = Bypass.open(port: 9002)
    {:ok, bypass: bypass}
  end

  test "an inbound message is stored and relayed to the sender's partner", %{bypass: bypass} do
    sender_phone = "15555555555"
    recipient_phone = "15555555556"
    proxy_phone = "15555555557"
    text = "Test message"

    sender = insert_user(sender_phone)
    recipient = insert_user(recipient_phone)
    conversation = insert_conversation(sender, recipient, proxy_phone)

    Bypass.expect bypass, fn outbound_sms_conn ->
      outbound_sms_conn = parse_body_params(outbound_sms_conn)

      assert outbound_sms_conn.params["to"] == recipient_phone
      assert outbound_sms_conn.params["from"] == proxy_phone
      assert outbound_sms_conn.params["text"] == text

      Conn.resp(outbound_sms_conn, 200, "")
    end

    inbound_sms_data = %{
      "msisdn": sender_phone,
      "to": proxy_phone,
      "messageId": "000000FFFB0356D1",
      "text": text,
      "type": "text",
      "message-timestamp": "2017-04-04 00:00:00"}
    inbound_sms_conn = conn(:get, "/receive", inbound_sms_data)
    opts = SMSReceiver.init([])

    inbound_sms_conn = SMSReceiver.call(inbound_sms_conn, opts)

    messages = Storage.all(Message)
    message = List.first(messages)
    assert length(messages) == 1
    assert message.conversation_id == conversation.id
    assert message.user_id == sender.id
    assert message.text == text
    assert %DateTime{} = message.timestamp

    assert inbound_sms_conn.state == :sent
    assert inbound_sms_conn.status == 200
  end
end
