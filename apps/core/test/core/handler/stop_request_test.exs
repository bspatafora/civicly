defmodule Core.Handler.StopRequestTest do
  use ExUnit.Case

  alias Ecto.Adapters.SQL.Sandbox
  alias Plug.Conn

  alias Core.Handler.StopRequest
  alias Core.Helpers
  alias Core.Helpers.MessageSpy
  alias Storage.Helpers, as: StorageHelpers
  alias Storage.{Conversation, User}
  alias Strings, as: S

  setup do
    :ok = Sandbox.checkout(Storage)
    Sandbox.mode(Storage, {:shared, self()})

    bypass = Bypass.open(port: 9002)
    {:ok, bypass: bypass}
  end

  test "handle/1 deletes the sender", %{bypass: bypass} do
    sms_relay = StorageHelpers.insert_sms_relay()
    user = StorageHelpers.insert_user()
    partner = StorageHelpers.insert_user()
    StorageHelpers.insert_conversation(
      %{active?: true,
        sms_relay_id: sms_relay.id,
        users: [user.id, partner.id]})
    message = Helpers.build_message(
      %{sender: user.phone,
        text: "STOP"})

    Bypass.expect bypass, &(Conn.resp(&1, 200, ""))

    StopRequest.handle(message)

    assert Storage.get(User, user.id) == nil
  end

  test "handle/1 inactivates the conversation when there is only one partner left", %{bypass: bypass} do
    sms_relay = StorageHelpers.insert_sms_relay()
    user = StorageHelpers.insert_user()
    partner = StorageHelpers.insert_user()
    conversation = StorageHelpers.insert_conversation(
      %{active?: true,
        sms_relay_id: sms_relay.id,
        users: [user.id, partner.id]})
    message = Helpers.build_message(
      %{sender: user.phone,
        text: "STOP"})

    Bypass.expect bypass, &(Conn.resp(&1, 200, ""))

    StopRequest.handle(message)

    conversation = Storage.get(Conversation, conversation.id)
    assert conversation.active? == false
  end

  test "handle/1 does not inactivate the conversation when there is more than one partner left", %{bypass: bypass} do
    sms_relay = StorageHelpers.insert_sms_relay()
    user = StorageHelpers.insert_user()
    partner1 = StorageHelpers.insert_user()
    partner2 = StorageHelpers.insert_user()
    conversation = StorageHelpers.insert_conversation(
      %{active?: true,
        sms_relay_id: sms_relay.id,
        users: [user.id, partner1.id, partner2.id]})
    message = Helpers.build_message(
      %{sender: user.phone,
        text: "STOP"})

    Bypass.expect bypass, &(Conn.resp(&1, 200, ""))

    StopRequest.handle(message)

    conversation = Storage.get(Conversation, conversation.id)
    assert conversation.active? == true
  end

  test "handle/1 notifies the sender and their partners when the sender is in an active conversation", %{bypass: bypass} do
    sms_relay = StorageHelpers.insert_sms_relay()
    user = StorageHelpers.insert_user()
    partner1 = StorageHelpers.insert_user()
    partner2 = StorageHelpers.insert_user()
    StorageHelpers.insert_conversation(
      %{active?: true,
        sms_relay_id: sms_relay.id,
        users: [user.id, partner1.id, partner2.id]})
    message = Helpers.build_message(
      %{sender: user.phone,
        text: "STOP"})

    {:ok, messages} = MessageSpy.new()
    Bypass.expect bypass, fn conn ->
      conn = Helpers.parse_body_params(conn)
      MessageSpy.record(messages, conn.params["recipient"], conn.params["text"])
      Conn.resp(conn, 200, "")
    end

    StopRequest.handle(message)

    messages = MessageSpy.get(messages)
    assert length(messages) == 3
    user_deletion_message = %{recipient: user.phone, text: S.user_deletion()}
    partner_deletion_message1 =
      %{recipient: partner1.phone,
        text: S.partner_deletion(user.name)}
    partner_deletion_message2 =
      %{recipient: partner2.phone,
        text: S.partner_deletion(user.name)}
    assert Enum.member?(messages, user_deletion_message)
    assert Enum.member?(messages, partner_deletion_message1)
    assert Enum.member?(messages, partner_deletion_message2)
  end

  test "handle/1 notifies just the sender when the sender is not in an active conversation", %{bypass: bypass} do
    sms_relay = StorageHelpers.insert_sms_relay()
    user = StorageHelpers.insert_user()
    partner1 = StorageHelpers.insert_user()
    partner2 = StorageHelpers.insert_user()
    StorageHelpers.insert_conversation(
      %{active?: false,
        sms_relay_id: sms_relay.id,
        users: [user.id, partner1.id, partner2.id]})
    message = Helpers.build_message(
      %{sender: user.phone,
        text: "STOP"})

    {:ok, messages} = MessageSpy.new()
    Bypass.expect bypass, fn conn ->
      conn = Helpers.parse_body_params(conn)
      MessageSpy.record(messages, conn.params["recipient"], conn.params["text"])
      Conn.resp(conn, 200, "")
    end

    StopRequest.handle(message)

    messages = MessageSpy.get(messages)
    assert length(messages) == 1
    user_deletion_message = %{recipient: user.phone, text: S.user_deletion()}
    assert Enum.member?(messages, user_deletion_message)
  end
end
