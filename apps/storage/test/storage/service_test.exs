defmodule Storage.ServiceTest do
  use ExUnit.Case

  alias Ecto.Adapters.SQL.Sandbox
  alias Storage.{Helpers, Message, Service, User}

  setup do
    :ok = Sandbox.checkout(Storage)
    Sandbox.mode(Storage, {:shared, self()})
  end

  test "current_partner_and_proxy_phones/1 provides the partner and proxy phone numbers of the user's current conversation" do
    user1 = Helpers.insert_user()
    user2 = Helpers.insert_user()

    {:ok, old_start, _} = DateTime.from_iso8601("2017-03-23 00:00:00Z")
    Helpers.insert_conversation(%{
      left_user_id: user1.id,
      right_user_id: user2.id,
      start: old_start})

    {:ok, current_start, _} = DateTime.from_iso8601("2017-03-27 00:00:00Z")
    current_conversation = Helpers.insert_conversation(%{
        left_user_id: user1.id,
        right_user_id: user2.id,
        start: current_start})

    {partner_phone, proxy_phone} =
      Service.current_partner_and_proxy_phones(user1.phone)

    assert partner_phone == user2.phone
    assert proxy_phone == current_conversation.proxy_phone

    {partner_phone, proxy_phone} =
      Service.current_partner_and_proxy_phones(user2.phone)

    assert partner_phone == user1.phone
    assert proxy_phone == current_conversation.proxy_phone
  end

  test "store_message/1 stores a message" do
    sender_phone = "5555555555"
    recipient_phone = "5555555556"
    text = "Test message"

    sender = Helpers.insert_user(sender_phone)
    recipient = Helpers.insert_user(recipient_phone)

    {:ok, old_start, _} = DateTime.from_iso8601("2017-05-27 00:00:00Z")
    Helpers.insert_conversation(%{
      left_user_id: sender.id,
      right_user_id: recipient.id,
      start: old_start})

    {:ok, current_start, _} = DateTime.from_iso8601("2017-05-31 00:00:00Z")
    current_conversation = Helpers.insert_conversation(%{
        left_user_id: sender.id,
        right_user_id: recipient.id,
        start: current_start})

    message = %SMSMessage{
      recipient: recipient_phone,
      sender: sender_phone,
      text: text,
      timestamp: DateTime.utc_now}

    Service.store_message(message)

    messages = Storage.all(Message)
    message = List.first(messages)
    assert length(messages) == 1
    assert message.conversation_id == current_conversation.id
    assert message.user_id == sender.id
    assert message.text == text
    assert %DateTime{} = message.timestamp
  end

  test "insert_user/2 inserts a user" do
    name = "Test User"
    phone = "5555555555"

    {:ok, user} = Service.insert_user(name, phone)

    assert user
    users = Storage.all(User)
    user = List.first(users)
    assert length(users) == 1
    assert user.name == name
    assert user.phone == phone
  end
end
