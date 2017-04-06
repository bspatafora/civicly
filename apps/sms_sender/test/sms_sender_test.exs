defmodule SMSSenderTest do
  use ExUnit.Case, async: true

  alias Plug.{Conn, Parsers}

  def parse_body_params(conn) do
    opts = Parsers.init([parsers: [Plug.Parsers.URLENCODED]])
    Parsers.call(conn, opts)
  end

  def get_config(key) do
    Application.get_env(:sms_sender, key)
  end

  setup do
    bypass = Bypass.open(port: 9002)
    {:ok, bypass: bypass}
  end

  test "a message is sent correctly", %{bypass: bypass} do
    recipient_phone = "15555555555"
    proxy_phone = "15555555556"
    text = "Test message"

    Bypass.expect bypass, fn outbound_sms_conn ->
      outbound_sms_conn = parse_body_params(outbound_sms_conn)

      assert outbound_sms_conn.request_path == "/sms/json"
      assert outbound_sms_conn.method == "POST"

      assert outbound_sms_conn.params["api_key"] == get_config(:api_key)
      assert outbound_sms_conn.params["api_secret"] == get_config(:api_secret)

      assert outbound_sms_conn.params["to"] == recipient_phone
      assert outbound_sms_conn.params["from"] == proxy_phone
      assert outbound_sms_conn.params["text"] == text

      Conn.resp(outbound_sms_conn, 200, "")
    end

    message = %SMSMessage{
      recipient: recipient_phone,
      sender: proxy_phone,
      text: text}

    SMSSender.send(message)
  end
end
