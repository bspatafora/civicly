defmodule Storage.ServiceTest do
  use ExUnit.Case

  alias Ecto.Adapters.SQL.Sandbox
  alias Storage.{Helpers, Message, Service, User}

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
  end

  test "current_partner_phone_and_sms_relay_ip/1 provides the partner phone and SMS relay IP of the user's current conversation" do
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
    current_conversation = Storage.preload(current_conversation, :sms_relay)

    {partner_phone, sms_relay_ip, sms_relay_phone} =
      Service.current_conversation_details(user1.phone)

    assert partner_phone == user2.phone
    assert sms_relay_ip == current_conversation.sms_relay.ip
    assert sms_relay_phone == current_conversation.sms_relay.phone

    {partner_phone, sms_relay_ip, sms_relay_phone} =
      Service.current_conversation_details(user2.phone)

    assert partner_phone == user1.phone
    assert sms_relay_ip == current_conversation.sms_relay.ip
    assert sms_relay_phone == current_conversation.sms_relay.phone
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

    message = build_message(%{
      recipient: recipient_phone,
      sender: sender_phone,
      text: text})

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

  test "update_first_sms_relay_ip/1 updates the IP of the first SMS relay in the database" do
    Helpers.insert_sms_relay(%{ip: "127.0.0.1"})
    Helpers.insert_sms_relay(%{ip: "localhost"})

    Service.update_first_sms_relay_ip("127.0.0.2")

    assert Helpers.first_sms_relay_ip() == "127.0.0.2"
  end

  test "refresh_sms_relay_ip/1 replaces the message's SMS relay IP with the IP of the first SMS relay in the database" do
    first_sms_relay = Helpers.insert_sms_relay(%{ip: "127.0.0.1"})
    Helpers.insert_sms_relay(%{ip: "localhost"})
    message = build_message(%{sms_relay_ip: "localhost"})

    message = Service.refresh_sms_relay_ip(message)

    assert message.sms_relay_ip == first_sms_relay.ip
  end
end
