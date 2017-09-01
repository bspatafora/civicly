defmodule SMSReceiverTest do
  use ExUnit.Case
  use Plug.Test

  alias Ecto.Adapters.SQL.Sandbox
  alias Plug.{Conn, Parsers}
  alias Storage.Helpers
  alias Strings, as: S

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

  test "it relays an inbound message to the sender's partner", %{bypass: bypass} do
    user = Helpers.insert_user()
    partner = Helpers.insert_user()
    sms_relay = Helpers.insert_sms_relay(%{ip: "localhost"})
    Helpers.insert_conversation(%{
      active?: true,
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
      assert outbound_sms_conn.params["text"] == S.prepend_name(user.name, text)
      Conn.resp(outbound_sms_conn, 200, "")
    end

    SMSReceiver.call(inbound_sms_conn, SMSReceiver.init([]))
  end

  test "it updates the first SMS relay IP on a heartbeat request" do
    Helpers.insert_sms_relay()
    conn = conn(:post, "/sms_relay_heartbeat", %{})
    conn = put_req_header(conn, "content-type", "application/json")
    conn = %{conn | remote_ip: {0, 0, 0, 0}}

    SMSReceiver.call(conn, SMSReceiver.init([]))

    assert Helpers.first_sms_relay_ip == "0.0.0.0"
  end

  test "it updates the first SMS relay IP on an inbound message request", %{bypass: bypass} do
    Helpers.insert_sms_relay(%{ip: "localhost"})
    second_sms_relay = Helpers.insert_sms_relay(%{ip: "localhost"})
    user = Helpers.insert_user()
    Helpers.insert_conversation(%{
      active?: true,
      sms_relay_id: second_sms_relay.id,
      users: [user.id, Helpers.insert_user().id]})
    data = %{
      "id": "3c4d2d9b-5ccb-4d47-9b85-ac723f334ba3",
      "recipient": second_sms_relay.phone,
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
end
