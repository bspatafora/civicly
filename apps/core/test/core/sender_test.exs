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

  test "send_command_output/2 sends a message with the specified text to the original sender", %{bypass: bypass} do
    StorageHelpers.insert_sms_relay()
    text = "Test message"
    sender_phone = "5555555555"
    message = Helpers.build_message(
      %{recipient: "5555555556",
        sender: sender_phone,
        text: text})

    Bypass.expect bypass, fn conn ->
      conn = Helpers.parse_body_params(conn)
      assert conn.params["recipient"] == sender_phone
      assert conn.params["text"] == text
      Conn.resp(conn, 200, "")
    end

    Sender.send_command_output(text, message)
  end

  test "send_to_all/2 sends a message with the specified text to all users", %{bypass: bypass} do
    StorageHelpers.insert_sms_relay()
    user1 = StorageHelpers.insert_user()
    user2 = StorageHelpers.insert_user()
    text = "Test message"
    message = Helpers.build_message(
      %{recipient: "5555555555",
        text: text})

    {:ok, messages} = MessageSpy.new()
    Bypass.expect bypass, fn conn ->
      conn = Helpers.parse_body_params(conn)
      MessageSpy.record(messages, conn.params["recipient"], conn.params["text"])
      Conn.resp(conn, 200, "")
    end

    Sender.send_to_all(text, message)

    messages = MessageSpy.get(messages)
    assert length(messages) == 2
    assert Enum.member?(messages, %{recipient: user1.phone, text: text})
    assert Enum.member?(messages, %{recipient: user2.phone, text: text})
  end

  test "send_to_active/2 sends a message with the specified text to all users in active conversations", %{bypass: bypass} do
    sms_relay = StorageHelpers.insert_sms_relay()
    user1 = StorageHelpers.insert_user()
    user2 = StorageHelpers.insert_user()
    inactive = StorageHelpers.insert_user()
    StorageHelpers.insert_conversation(
      %{active?: true,
        iteration: 1,
        sms_relay_id: sms_relay.id,
        users: [user1.id, user2.id]})
    text = "Test message"
    message = Helpers.build_message(
      %{recipient: "5555555555",
        text: text})

    {:ok, messages} = MessageSpy.new()
    Bypass.expect bypass, fn conn ->
      conn = Helpers.parse_body_params(conn)
      MessageSpy.record(messages, conn.params["recipient"], conn.params["text"])
      Conn.resp(conn, 200, "")
    end

    Sender.send_to_active(text, message)

    messages = MessageSpy.get(messages)
    assert length(messages) == 2
    assert Enum.member?(messages, %{recipient: user1.phone, text: text})
    assert Enum.member?(messages, %{recipient: user2.phone, text: text})
    assert !Enum.member?(messages, %{recipient: inactive.phone, text: text})
  end

  test "send_message/3 sends a message with the specified text to each recipient", %{bypass: bypass} do
    StorageHelpers.insert_sms_relay()
    text = "Test message"
    recipient1_phone = "5555555556"
    recipient2_phone = "5555555557"
    message = Helpers.build_message(
      %{recipient: "5555555555",
        text: text})

    {:ok, messages} = MessageSpy.new()
    Bypass.expect bypass, fn conn ->
      conn = Helpers.parse_body_params(conn)
      MessageSpy.record(messages, conn.params["recipient"], conn.params["text"])
      Conn.resp(conn, 200, "")
    end

    Sender.send_message(text, [recipient1_phone, recipient2_phone], message)

    messages = MessageSpy.get(messages)
    assert length(messages) == 2
    assert Enum.member?(messages, %{recipient: recipient1_phone, text: text})
    assert Enum.member?(messages, %{recipient: recipient2_phone, text: text})
  end
end
