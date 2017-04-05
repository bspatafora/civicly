defmodule SMSReceiverTest do
  use ExUnit.Case
  use Plug.Test

  def insert_users_and_conversation(left_user_phone, right_user_phone, proxy_phone) do
    params = %{
      left_user_id: insert_user(left_user_phone).id,
      right_user_id: insert_user(right_user_phone).id,
      proxy_phone: proxy_phone,
      start: to_string(Ecto.DateTime.utc)}
    changeset = Storage.Conversation.changeset(%Storage.Conversation{}, params)

    Storage.insert(changeset)
  end

  def insert_user(phone) do
    params = %{name: "Test User", phone: phone}
    changeset = Storage.User.changeset(%Storage.User{}, params)

    {:ok, user} = Storage.insert(changeset)
    user
  end

  def parse_body_params(conn) do
    opts = Plug.Parsers.init([parsers: [Plug.Parsers.URLENCODED]])
    Plug.Parsers.call(conn, opts)
  end

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Storage)
    Ecto.Adapters.SQL.Sandbox.mode(Storage, {:shared, self()})

    bypass = Bypass.open(port: 9002)
    {:ok, bypass: bypass}
  end

  test "an inbound message is relayed to the sender's partner", %{bypass: bypass} do
    sender_phone = "15555555555"
    recipient_phone = "15555555556"
    proxy_phone = "15555555557"
    text = "Test message"

    insert_users_and_conversation(sender_phone, recipient_phone, proxy_phone)

    Bypass.expect bypass, fn outbound_sms_conn ->
      outbound_sms_conn = parse_body_params(outbound_sms_conn)

      assert outbound_sms_conn.params["to"] == recipient_phone
      assert outbound_sms_conn.params["from"] == proxy_phone
      assert outbound_sms_conn.params["text"] == text

      Plug.Conn.resp(outbound_sms_conn, 200, "")
    end

    inbound_sms_data = %{
      "msisdn": sender_phone,
      "to": proxy_phone,
      "messageId": "000000FFFB0356D1",
      "text": text,
      "type": "text",
      "message-timestamp": "2017-04-04+00:00:00"}

    inbound_sms_conn= conn(:get, "/receive", inbound_sms_data)
                          |> SMSReceiver.call(SMSReceiver.init([]))

    assert inbound_sms_conn.state == :sent
    assert inbound_sms_conn.status == 200
  end
end
