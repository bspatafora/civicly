defmodule Core.SenderTest do
  use ExUnit.Case

  alias Ecto.Adapters.SQL.Sandbox
  alias Plug.Conn

  alias Core.{Helpers, Sender}
  alias Core.Helpers.MessageSpy
  alias Storage.Helpers, as: StorageHelpers

  setup do
    :ok = Sandbox.checkout(Storage)
    Sandbox.mode(Storage, {:shared, self()})

    bypass = Bypass.open(port: 9002)
    {:ok, bypass: bypass}
  end

  test "send_message/3 sends a message with the provided text to each recipient", %{bypass: bypass} do
    StorageHelpers.insert_sms_relay(%{ip: "localhost"})
    text = "Test message"
    recipient1_phone = "5555555556"
    recipient2_phone = "5555555557"

    {:ok, messages} = MessageSpy.new()
    Bypass.expect bypass, fn conn ->
      conn = Helpers.parse_body_params(conn)
      MessageSpy.record(messages, conn.params["recipient"], conn.params["text"])
      Conn.resp(conn, 200, "")
    end

    message = Helpers.build_message(%{
      recipient: "5555555555",
      sms_relay_ip: "localhost",
      text: text})

    Sender.send_message(text, [recipient1_phone, recipient2_phone], message)

    messages = MessageSpy.get(messages)
    assert length(messages) == 2
    assert Enum.member?(messages, %{recipient: recipient1_phone, text: text})
    assert Enum.member?(messages, %{recipient: recipient2_phone, text: text})
  end

  test "send_command_output/2 sends a message with the provided text to the user who issued the command", %{bypass: bypass} do
    StorageHelpers.insert_sms_relay(%{ip: "localhost"})
    text = "Test message"
    user_phone = "5555555555"

    Bypass.expect bypass, fn conn ->
      conn = Helpers.parse_body_params(conn)

      assert conn.params["recipient"] == user_phone
      assert conn.params["text"] == text

      Conn.resp(conn, 200, "")
    end

    message = Helpers.build_message(%{
      sender: user_phone,
      sms_relay_ip: "localhost",
      text: text})

    Sender.send_command_output(text, message)
  end
end
