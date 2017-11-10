defmodule Core.Action.ReminderTest do
  use ExUnit.Case

  alias Ecto.Adapters.SQL.Sandbox
  alias Plug.Conn

  alias Core.Action.Reminder
  alias Core.Helpers
  alias Core.Helpers.MessageSpy
  alias Storage.Helpers, as: StorageHelpers
  alias Strings, as: S

  setup do
    :ok = Sandbox.checkout(Storage)
    Sandbox.mode(Storage, {:shared, self()})

    bypass = Bypass.open(port: 9002)
    {:ok, bypass: bypass}
  end

  test "send/1 sends a reminder to all users in active conversations who have yet to send a message", %{bypass: bypass} do
    sms_relay = StorageHelpers.insert_sms_relay()
    engaged = StorageHelpers.insert_user()
    not_yet_engaged = StorageHelpers.insert_user()
    inactive1 = StorageHelpers.insert_user()
    inactive2 = StorageHelpers.insert_user()
    conversation = StorageHelpers.insert_conversation(
      %{active?: true,
        iteration: 1,
        sms_relay_id: sms_relay.id,
        users: [engaged.id, not_yet_engaged.id]})
    StorageHelpers.insert_conversation(
      %{active?: false,
        iteration: 1,
        sms_relay_id: sms_relay.id,
        users: [inactive1.id, inactive2.id]})
    StorageHelpers.insert_message(
      %{conversation_id: conversation.id,
        user_id: engaged.id})

    {:ok, messages} = MessageSpy.new()
    Bypass.expect bypass, fn conn ->
      conn = Helpers.parse_body_params(conn)
      MessageSpy.record(messages, conn.params["recipient"], conn.params["text"])
      Conn.resp(conn, 200, "")
    end

    Reminder.send()

    messages = MessageSpy.get(messages)
    assert length(messages) == 1
    reminder = S.conversation_reminder()
    assert Enum.member?(messages, %{recipient: not_yet_engaged.phone, text: reminder})
  end
end
