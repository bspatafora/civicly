defmodule SMSSenderTest do
  use ExUnit.Case, async: true

  alias Storage.Helpers
  alias Plug.{Conn, Parsers}

  def parse_body_params(conn) do
    opts = Parsers.init([parsers: [:json], json_decoder: Poison])
    Parsers.call(conn, opts)
  end

  setup do
    bypass = Bypass.open(port: 9002)
    {:ok, bypass: bypass}
  end

  test "send/1 sends a message correctly", %{bypass: bypass} do
    recipient_phone = "5555555555"
    text = "Test message"

    Bypass.expect bypass, fn outbound_sms_conn ->
      outbound_sms_conn = parse_body_params(outbound_sms_conn)

      assert outbound_sms_conn.request_path == "/send"
      assert outbound_sms_conn.method == "POST"

      assert outbound_sms_conn.params["recipient"] == recipient_phone
      assert outbound_sms_conn.params["text"] == text

      Conn.resp(outbound_sms_conn, 200, "")
    end

    message = %SMSMessage{
      recipient: recipient_phone,
      sender: "5555555556",
      sms_relay_ip: "localhost",
      text: text,
      timestamp: DateTime.utc_now,
      uuid: Helpers.uuid()}

    SMSSender.send(message)
  end
end
