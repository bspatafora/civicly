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
    sms_relay = Helpers.insert_sms_relay()
    user1 = Helpers.insert_user()
    user2 = Helpers.insert_user()
    user3 = Helpers.insert_user()
    user4 = Helpers.insert_user()
    user5 = Helpers.insert_user()
    Helpers.insert_conversation(
      %{active?: false,
        iteration: 1,
        sms_relay_id: sms_relay.id,
        users: [user1.id, user2.id, user3.id]})
    Helpers.insert_conversation(
      %{active?: true,
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
    Helpers.insert_conversation(
      %{active?: false,
        iteration: 1,
        users: [sender.id, recipient.id]})
    current_conversation = Helpers.insert_conversation(
      %{active?: true,
        iteration: 2,
        users: [sender.id, recipient.id]})
    message = build_message(
      %{recipient: recipient.phone,
        sender: sender.phone,
        text: text})

    Service.store_message(message)

    message = List.first(Storage.all(Message))
    assert message.conversation_id == current_conversation.id
    assert message.user_id == sender.id
    assert message.text == text
    assert %DateTime{} = message.timestamp
  end

  test "insert_user/2 inserts a user" do
    name = "Test User"
    phone = "5555555555"

    {:ok, _} = Service.insert_user(name, phone)

    user = List.first(Storage.all(User))
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
    message = build_message(%{sms_relay_ip: "localhost"})

    message = Service.refresh_sms_relay_ip(message)

    assert message.sms_relay_ip == first_sms_relay.ip
  end

  test "delete_user/1 deletes the user with the given phone, along with their messages and links to conversations" do
    sms_relay = Helpers.insert_sms_relay()
    user = Helpers.insert_user()
    partner = Helpers.insert_user()
    conversation = Helpers.insert_conversation(
      %{active?: true,
        iteration: 1,
        sms_relay_id: sms_relay.id,
        users: [user.id, partner.id]})
    user_message = Helpers.insert_message(
      %{conversation_id: conversation.id,
        user_id: user.id})
    partner_message = Helpers.insert_message(
      %{conversation_id: conversation.id,
        user_id: partner.id})

    Service.delete_user(user.phone)

    assert Storage.get(User, user.id) == nil

    conversation = Storage.get(Conversation, conversation.id)
    conversation = Storage.preload(conversation, :users)
    assert length(conversation.users) == 1

    assert Storage.get(Message, user_message.id) == nil
    assert Storage.get(Message, partner_message.id) != nil
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
    Helpers.insert_conversation(
      %{active?: true,
        iteration: 1,
        sms_relay_id: sms_relay.id,
        users: [user.id, partner.id]})
    Helpers.insert_conversation(
      %{active?: false,
        iteration: 2,
        sms_relay_id: sms_relay.id,
        users: [user.id, partner.id]})

    assert Service.active_conversation?(user.phone) == false
  end

  test "active_conversation?/1 returns false when the user has no conversations" do
    Helpers.insert_sms_relay()
    user = Helpers.insert_user()

    assert Service.active_conversation?(user.phone) == false
  end

  test "active_conversation?/1 returns true when the user's current conversation is active" do
    sms_relay = Helpers.insert_sms_relay()
    user = Helpers.insert_user()
    partner = Helpers.insert_user()
    Helpers.insert_conversation(
      %{active?: false,
        iteration: 1,
        sms_relay_id: sms_relay.id,
        users: [user.id, partner.id]})
    Helpers.insert_conversation(
      %{active?: true,
        iteration: 2,
        sms_relay_id: sms_relay.id,
        users: [user.id, partner.id]})

    assert Service.active_conversation?(user.phone) == true
  end

  test "activate/1 sets the conversation's status to active" do
    sms_relay = Helpers.insert_sms_relay()
    conversation = Helpers.insert_conversation(
      %{active?: false,
        iteration: 1,
        sms_relay_id: sms_relay.id,
        users: [Helpers.insert_user().id, Helpers.insert_user().id]})

    Service.activate(conversation)

    conversation = Storage.get(Conversation, conversation.id)
    assert conversation.active? == true
  end

  test "inactivate_all_conversations/0 sets the status of all conversations to inactive" do
    sms_relay = Helpers.insert_sms_relay()
    conversation1 = Helpers.insert_conversation(
      %{active?: true,
        iteration: 1,
        sms_relay_id: sms_relay.id,
        users: [Helpers.insert_user().id, Helpers.insert_user().id]})
    conversation2 = Helpers.insert_conversation(
      %{active?: true,
        iteration: 2,
        sms_relay_id: sms_relay.id,
        users: [Helpers.insert_user().id, Helpers.insert_user().id]})

    Service.inactivate_all_conversations()

    [conversation1, conversation2]
      |> Enum.each(&(Storage.get(Conversation, &1.id).active? == false))
  end

  test "all_phones/0 returns the phone of every user" do
    user1 = Helpers.insert_user()
    user2 = Helpers.insert_user()

    all_phones = Service.all_phones()

    assert length(all_phones) == 2
    assert Enum.member?(all_phones, user1.phone)
    assert Enum.member?(all_phones, user2.phone)
  end

  test "active_phones/0 returns the phone of every user active in the current iteration" do
    sms_relay = Helpers.insert_sms_relay()
    user1 = Helpers.insert_user()
    user2 = Helpers.insert_user()
    inactive_user1 = Helpers.insert_user()
    inactive_user2 = Helpers.insert_user()
    new_user = Helpers.insert_user()
    Helpers.insert_conversation(
      %{active?: false,
        iteration: 1,
        sms_relay_id: sms_relay.id,
        users: [inactive_user1.id, inactive_user2.id]})
    Helpers.insert_conversation(
      %{active?: true,
        iteration: 2,
        sms_relay_id: sms_relay.id,
        users: [user1.id, user2.id]})

    active_phones = Service.active_phones()

    assert length(active_phones) == 2
    assert Enum.member?(active_phones, user1.phone)
    assert Enum.member?(active_phones, user2.phone)
    assert !Enum.member?(active_phones, inactive_user1.phone)
    assert !Enum.member?(active_phones, inactive_user2.phone)
    assert !Enum.member?(active_phones, new_user.phone)
  end

  test "user?/1 returns true if a user with the given phone exists" do
    user = Helpers.insert_user()

    assert Service.user?(user.phone) == true
  end

  test "user?/1 returns false if no user with the given phone exists" do
    assert Service.user?("5555555555") == false
  end
end
