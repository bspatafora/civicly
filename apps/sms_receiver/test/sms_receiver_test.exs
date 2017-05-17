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
    opts = Parsers.init([parsers: [:json], json_decoder: Poison])
    Parsers.call(conn, opts)
  end

  setup do
    :ok = Sandbox.checkout(Storage)
    Sandbox.mode(Storage, {:shared, self()})

    bypass = Bypass.open(port: 9002)
    {:ok, bypass: bypass}
  end

  test "an inbound message is stored and relayed to the sender's partner", %{bypass: bypass} do
    sender_phone = "5555555555"
    recipient_phone = "5555555556"
    proxy_phone = "5555555557"
    text = "Test message"

    sender = insert_user(sender_phone)
    recipient = insert_user(recipient_phone)
    conversation = insert_conversation(sender, recipient, proxy_phone)

    Bypass.expect bypass, fn outbound_sms_conn ->
      outbound_sms_conn = parse_body_params(outbound_sms_conn)

      assert outbound_sms_conn.params["recipient"] == recipient_phone
      assert outbound_sms_conn.params["text"] == text

      Conn.resp(outbound_sms_conn, 200, "")
    end

    inbound_sms_data = %{
      "id": "3c4d2d9b-5ccb-4d47-9b85-ac723f334ba3",
      "recipient": proxy_phone,
      "sender": sender_phone,
      "text": text,
      "timestamp": "2017-04-04T00:00:00.000Z"}
    inbound_sms_conn = conn(:post, "/receive", inbound_sms_data)
    inbound_sms_conn = put_req_header(inbound_sms_conn, "content-type", "application/json")
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
