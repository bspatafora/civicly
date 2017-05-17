defmodule SMSSenderTest do
  use ExUnit.Case, async: true

  alias Plug.{Conn, Parsers}

  def parse_body_params(conn) do
    opts = Parsers.init([parsers: [Plug.Parsers.URLENCODED]])
    Parsers.call(conn, opts)
  end

  setup do
    bypass = Bypass.open(port: 9002)
    {:ok, bypass: bypass}
  end

  test "send/1 sends a message correctly", %{bypass: bypass} do
    recipient_phone = "5555555555"
    proxy_phone = "5555555556"
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
      sender: proxy_phone,
      text: text,
      timestamp: DateTime.utc_now}

    SMSSender.send(message)
  end
end
