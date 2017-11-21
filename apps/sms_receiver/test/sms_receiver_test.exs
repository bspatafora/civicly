defmodule SMSReceiverTest do
  use ExUnit.Case
  use Plug.Test

  alias Ecto.Adapters.SQL.Sandbox
  alias Plug.{Conn, Parsers}
  alias Storage.Helpers

  defmodule MessageSpy do
    def new do
      Agent.start_link(fn -> [] end)
    end

    def record(agent, recipient, text) do
      Agent.update(agent, &([%{recipient: recipient, text: text} | &1]))
    end

    def get(agent) do
      Agent.get(agent, &(&1))
    end
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

  test "post /receive relays an inbound message to the sender's partner", %{bypass: bypass} do
    sms_relay = Helpers.insert_sms_relay()
    user = Helpers.insert_user()
    partner = Helpers.insert_user()
    Helpers.insert_conversation(
      %{active?: true,
        sms_relay_id: sms_relay.id,
        users: [user.id, partner.id]})
    text = "Test message"
    inbound_sms_data = %{
      "id": "3c4d2d9b-5ccb-4d47-9b85-ac723f334ba3",
      "recipient": sms_relay.phone,
      "sender": user.phone,
      "text": text,
      "timestamp": "2017-04-04T00:00:00.000Z"}
    inbound_sms_conn = conn(:post, "/receive", inbound_sms_data)
    inbound_sms_conn = put_req_header(inbound_sms_conn, "content-type", "application/json")

    Bypass.expect bypass, fn outbound_sms_conn ->
      outbound_sms_conn = parse_body_params(outbound_sms_conn)
      assert outbound_sms_conn.params["recipient"] == partner.phone
      assert outbound_sms_conn.params["text"] == text
      Conn.resp(outbound_sms_conn, 200, "")
    end

    SMSReceiver.call(inbound_sms_conn, SMSReceiver.init([]))
  end

  test "post /receive strips the sender phone to nine digits", %{bypass: bypass} do
    sms_relay = Helpers.insert_sms_relay()
    user = Helpers.insert_user()
    partner = Helpers.insert_user()
    Helpers.insert_conversation(
      %{active?: true,
        sms_relay_id: sms_relay.id,
        users: [user.id, partner.id]})
    text = "Test message"
    inbound_sms_data = %{
      "id": "3c4d2d9b-5ccb-4d47-9b85-ac723f334ba3",
      "recipient": sms_relay.phone,
      "sender": "+1#{user.phone}",
      "text": text,
      "timestamp": "2017-04-04T00:00:00.000Z"}
    inbound_sms_conn = conn(:post, "/receive", inbound_sms_data)
    inbound_sms_conn = put_req_header(inbound_sms_conn, "content-type", "application/json")

    Bypass.expect bypass, &(Conn.resp(&1, 200, ""))

    SMSReceiver.call(inbound_sms_conn, SMSReceiver.init([]))
  end

  test "post /receive updates the first SMS relay IP", %{bypass: bypass} do
    sms_relay = Helpers.insert_sms_relay(%{ip: "localhost"})
    user = Helpers.insert_user()
    Helpers.insert_conversation(%{
      active?: true,
      sms_relay_id: sms_relay.id,
      users: [user.id, Helpers.insert_user().id]})
    data = %{
      "id": "3c4d2d9b-5ccb-4d47-9b85-ac723f334ba3",
      "recipient": sms_relay.phone,
      "sender": user.phone,
      "text": "Test message",
      "timestamp": "2017-06-14T00:00:00.000Z"}
    conn = conn(:post, "/receive", data)
    conn = put_req_header(conn, "content-type", "application/json")
    conn = %{conn | remote_ip: {0, 0, 0, 0}}

    Bypass.expect bypass, &(Conn.resp(&1, 200, ""))

    SMSReceiver.call(conn, SMSReceiver.init([]))

    assert Helpers.first_sms_relay_ip() == "0.0.0.0"
  end

  test "post /receive drops duplicate messages", %{bypass: bypass} do
    sms_relay = Helpers.insert_sms_relay()
    user = Helpers.insert_user()
    partner = Helpers.insert_user()
    Helpers.insert_conversation(
      %{active?: true,
        sms_relay_id: sms_relay.id,
        users: [user.id, partner.id]})
    text = "Test message"

    inbound_sms_data1 = %{
      "id": "3c4d2d9b-5ccb-4d47-9b85-ac723f334ba3",
      "recipient": sms_relay.phone,
      "sender": user.phone,
      "text": text,
      "timestamp": DateTime.to_iso8601(DateTime.utc_now())}
    inbound_sms_conn1 = conn(:post, "/receive", inbound_sms_data1)
    inbound_sms_conn1 = put_req_header(inbound_sms_conn1, "content-type", "application/json")

    inbound_sms_data2 = %{
      "id": "a7517efe-f74a-4b0e-a732-0d0e20b7a88f",
      "recipient": sms_relay.phone,
      "sender": user.phone,
      "text": text,
      "timestamp": DateTime.to_iso8601(DateTime.utc_now())}
    inbound_sms_conn2 = conn(:post, "/receive", inbound_sms_data2)
    inbound_sms_conn2 = put_req_header(inbound_sms_conn2, "content-type", "application/json")

    {:ok, messages} = MessageSpy.new()
    Bypass.expect bypass, fn outbound_sms_conn ->
      outbound_sms_conn = parse_body_params(outbound_sms_conn)

      recipient = outbound_sms_conn.params["recipient"]
      text = outbound_sms_conn.params["text"]
      MessageSpy.record(messages, recipient, text)

      Conn.resp(outbound_sms_conn, 200, "")
    end

    SMSReceiver.call(inbound_sms_conn1, SMSReceiver.init([]))
    SMSReceiver.call(inbound_sms_conn2, SMSReceiver.init([]))

    messages = MessageSpy.get(messages)
    assert length(messages) == 1
    assert Enum.member?(messages, %{recipient: partner.phone, text: text})
  end

  test "post /sms_relay_heartbeat updates the first SMS relay IP" do
    Helpers.insert_sms_relay(%{ip: "localhost"})
    conn = conn(:post, "/sms_relay_heartbeat", %{})
    conn = put_req_header(conn, "content-type", "application/json")
    conn = %{conn | remote_ip: {0, 0, 0, 0}}

    SMSReceiver.call(conn, SMSReceiver.init([]))

    assert Helpers.first_sms_relay_ip == "0.0.0.0"
  end
end
