defmodule Storage.ServiceTest do
  use ExUnit.Case

  alias Ecto.Adapters.SQL.Sandbox

  alias Storage.{Conversation, Helpers, Message, Service, User}

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

  test "partner_phones/1 provides the partner phones for a user's current conversation" do
    user1 = Helpers.insert_user()
    user2 = Helpers.insert_user()
    user3 = Helpers.insert_user()
    user4 = Helpers.insert_user()
    user5 = Helpers.insert_user()
    sms_relay = Helpers.insert_sms_relay()
    Helpers.insert_conversation(%{
      iteration: 1,
      sms_relay_id: sms_relay.id,
      users: [user1.id, user2.id, user3.id]})
    Helpers.insert_conversation(%{
      iteration: 2,
      sms_relay_id: sms_relay.id,
      users: [user1.id, user4.id, user5.id]})

    partner_phones = Service.partner_phones(user1.phone)

    assert length(partner_phones) == 2
    assert Enum.member?(partner_phones, user4.phone)
    assert Enum.member?(partner_phones, user5.phone)
  end

  test "store_message/1 stores a message" do
    sender = Helpers.insert_user()
    recipient = Helpers.insert_user()
    text = "Test message"

    Helpers.insert_conversation(%{
      iteration: 1,
      users: [sender.id, recipient.id]})

    current_conversation = Helpers.insert_conversation(%{
      iteration: 2,
      users: [sender.id, recipient.id]})

    message = build_message(%{
      recipient: recipient.phone,
      sender: sender.phone,
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

    {:ok, _} = Service.insert_user(name, phone)

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

  test "delete_user/1 deletes the user with the given phone" do
    user = Helpers.insert_user()

    Service.delete_user(user.phone)

    assert Storage.get(User, user.id) == nil
  end

  test "name/1 fetches the name of the user by phone" do
    user = Helpers.insert_user()

    name = Service.name(user.phone)

    assert name == user.name
  end

  test "first_sms_relay/0 fetches the first SMS relay" do
    Helpers.insert_sms_relay(%{ip: "0.0.0.0"})
    Helpers.insert_sms_relay(%{ip: "localhost"})

    sms_relay = Service.first_sms_relay()

    assert sms_relay.ip == "0.0.0.0"
  end

  test "current_conversations/0 fetches the conversations for the current iteration" do
    Helpers.insert_conversation(%{iteration: 1})
    conversation1 = Helpers.insert_conversation(%{iteration: 2})
    conversation2 = Helpers.insert_conversation(%{iteration: 2})

    conversations = Service.current_conversations()

    assert Enum.member?(conversations, conversation1)
    assert Enum.member?(conversations, conversation2)
  end

  test "current_conversations/0 preloads each conversation's users and SMS relay" do
    conversation = Helpers.insert_conversation()

    conversations = Service.current_conversations()

    fetched_conversation = List.first(conversations)
    assert fetched_conversation.users == conversation.users
    assert fetched_conversation.sms_relay == conversation.sms_relay
  end

  test "current_iteration/0 fetches the current iteration" do
    assert Service.current_iteration() == nil

    Helpers.insert_conversation(%{iteration: 1})

    assert Service.current_iteration() == 1
  end

  test "active_conversation?/1 returns false when the user's current conversation is inactive" do
    sms_relay = Helpers.insert_sms_relay()
    user = Helpers.insert_user()
    partner = Helpers.insert_user()
    Helpers.insert_conversation(%{
      active?: true,
      iteration: 1,
      sms_relay_id: sms_relay.id,
      users: [user.id, partner.id]})
    Helpers.insert_conversation(%{
      active?: false,
      iteration: 2,
      sms_relay_id: sms_relay.id,
      users: [user.id, partner.id]})

    assert Service.active_conversation?(user.phone) == false
  end

  test "active_conversation?/1 returns true when the user's current conversation is active" do
    sms_relay = Helpers.insert_sms_relay()
    user = Helpers.insert_user()
    partner = Helpers.insert_user()
    Helpers.insert_conversation(%{
      active?: false,
      iteration: 1,
      sms_relay_id: sms_relay.id,
      users: [user.id, partner.id]})
    Helpers.insert_conversation(%{
      active?: true,
      iteration: 2,
      sms_relay_id: sms_relay.id,
      users: [user.id, partner.id]})

    assert Service.active_conversation?(user.phone) == true
  end

  test "activate/1 sets the conversation's status to active" do
    sms_relay = Helpers.insert_sms_relay()
    conversation = Helpers.insert_conversation(%{
      active?: false,
      iteration: 1,
      sms_relay_id: sms_relay.id,
      users: [Helpers.insert_user().id, Helpers.insert_user().id]})

    Service.activate(conversation)

    conversation = Storage.get(Conversation, conversation.id)
    assert conversation.active? == true
  end

  test "inactivate_all_conversations/0 sets the status of all conversations to inactive" do
    sms_relay = Helpers.insert_sms_relay()
    conversation1 = Helpers.insert_conversation(%{
      active?: true,
      iteration: 1,
      sms_relay_id: sms_relay.id,
      users: [Helpers.insert_user().id, Helpers.insert_user().id]})
    conversation2 = Helpers.insert_conversation(%{
      active?: true,
      iteration: 2,
      sms_relay_id: sms_relay.id,
      users: [Helpers.insert_user().id, Helpers.insert_user().id]})

    Service.inactivate_all_conversations()

    [conversation1, conversation2]
      |> Enum.each(&(Storage.get(Conversation, &1.id).active? == false))
  end

  test "all_phones/0 returns every user phone" do
    user1 = Helpers.insert_user()
    user2 = Helpers.insert_user()

    all_phones = Service.all_phones()

    assert length(all_phones) == 2
    assert Enum.member?(all_phones, user1.phone)
    assert Enum.member?(all_phones, user2.phone)
  end
end
