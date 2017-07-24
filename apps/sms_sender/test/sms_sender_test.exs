defmodule SMSSenderTest do
  use ExUnit.Case

  alias Ecto.Adapters.SQL.Sandbox
  alias Plug.{Conn, Parsers}

  alias Storage.Helpers

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

  test "send/1 POSTS to the SMS relay's /send route with the recipient and text", %{bypass: bypass} do
    Helpers.insert_sms_relay(%{ip: "localhost"})
    recipient_phone = "5555555555"
    text = "Test message"

    Bypass.expect bypass, fn conn ->
      conn = parse_body_params(conn)

      assert conn.request_path == "/send"
      assert conn.method == "POST"

      assert conn.params["recipient"] == recipient_phone
      assert conn.params["text"] == text

      Conn.resp(conn, 200, "")
    end

    message = build_message(%{
      recipient: recipient_phone,
      sms_relay_ip: "localhost",
      text: text})

    SMSSender.send(message)
  end

  test "send/1 refreshes the message's SMS relay IP before sending", %{bypass: bypass} do
    Helpers.insert_sms_relay(%{ip: "localhost"})
    Helpers.insert_sms_relay(%{ip: "127.0.0.2"})
    recipient_phone = "5555555555"

    Bypass.expect bypass, &(Conn.resp(&1, 200, ""))

    message = build_message(%{
      recipient: recipient_phone,
      sms_relay_ip: "127.0.0.2"})

    SMSSender.send(message)
  end
end
