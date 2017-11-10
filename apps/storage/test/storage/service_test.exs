defmodule Storage.ServiceTest do
  use ExUnit.Case

  alias Ecto.Adapters.SQL.Sandbox

  alias Storage.{CommandHistory, Conversation, Helpers, Message,
                 RecentlyReceivedMessage, Service, User}

  def build_message(params \\ %{}) do
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
    assert user.tutorial_step == 1
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

  test "active_phones/0 returns the phone of every user with an active conversation" do
    sms_relay = Helpers.insert_sms_relay()
    active1 = Helpers.insert_user()
    active2 = Helpers.insert_user()
    inactive1 = Helpers.insert_user()
    inactive2 = Helpers.insert_user()
    new = Helpers.insert_user()
    Helpers.insert_conversation(
      %{active?: true,
        iteration: 1,
        sms_relay_id: sms_relay.id,
        users: [active1.id, active2.id]})
    Helpers.insert_conversation(
      %{active?: false,
        iteration: 1,
        sms_relay_id: sms_relay.id,
        users: [inactive1.id, inactive2.id]})

    active_phones = Service.active_phones()

    assert length(active_phones) == 2
    assert Enum.member?(active_phones, active1.phone)
    assert Enum.member?(active_phones, active2.phone)
    assert !Enum.member?(active_phones, inactive1.phone)
    assert !Enum.member?(active_phones, inactive2.phone)
    assert !Enum.member?(active_phones, new.phone)
  end

  test "user?/1 returns true if a user with the given phone exists" do
    user = Helpers.insert_user()

    assert Service.user?(user.phone) == true
  end

  test "user?/1 returns false if no user with the given phone exists" do
    assert Service.user?("5555555555") == false
  end

  test "in_tutorial?/1 returns true if the user has not yet completed the tutorial" do
    user = Helpers.insert_user(%{tutorial_step: 1})

    assert Service.in_tutorial?(user.phone) == true
  end

  test "in_tutorial?/1 returns false if the user has completed the tutorial" do
    user = Helpers.insert_user(%{tutorial_step: 0})

    assert Service.in_tutorial?(user.phone) == false
  end

  test "tutorial_step/1 returns the tutorial step the user is on" do
    user = Helpers.insert_user(%{tutorial_step: 1})

    assert Service.tutorial_step(user.phone) == 1
  end

  test "advance_tutorial/1 increments the tutorial step the user is on" do
    user = Helpers.insert_user(%{tutorial_step: 1})

    Service.advance_tutorial(user.phone)

    assert Service.tutorial_step(user.phone) == 2
  end

  test "advance_tutorial/1 sets the user's tutorial step to 0 when their current step is 5" do
    user = Helpers.insert_user(%{tutorial_step: 5})

    Service.advance_tutorial(user.phone)

    assert Service.tutorial_step(user.phone) == 0
  end

  test "name/1 returns the user's name" do
    user = Helpers.insert_user()

    assert Service.name(user.phone) == user.name
  end

  test "active_users/0 returns all users who have completed the tutorial" do
    Helpers.insert_user(%{tutorial_step: 0})
    Helpers.insert_user(%{tutorial_step: 0})
    Helpers.insert_user(%{tutorial_step: 1})
    Helpers.insert_user(%{tutorial_step: 2})
    Helpers.insert_user(%{tutorial_step: 3})
    Helpers.insert_user(%{tutorial_step: 4})
    Helpers.insert_user(%{tutorial_step: 5})

    assert length(Service.active_users) == 2
  end

  test "duplicate?/1 returns false if no message with the same sender and text was received in the last 5 minutes" do
    sender = "5555555555"
    text = "Test message"
    same_sender_different_text =
      %{sender: sender,
        text: "Different message",
        timestamp: DateTime.utc_now()}
    same_text_different_sender =
      %{sender: "5555555556",
        text: text,
        timestamp: DateTime.utc_now()}
    Helpers.insert_recently_received_message(same_sender_different_text)
    Helpers.insert_recently_received_message(same_text_different_sender)
    message = build_message(%{sender: sender, text: text})

    assert Service.duplicate?(message) == false
  end

  test "duplicate?/1 returns true if a message with the same sender and text was received in the last 5 minutes" do
    sender = "5555555555"
    text = "Test message"
    unix_now = DateTime.to_unix(DateTime.utc_now())
    almost_five_minutes_ago = DateTime.from_unix!(unix_now - 299)
    params =
      %{sender: sender,
        text: text,
        timestamp: almost_five_minutes_ago}
    Helpers.insert_recently_received_message(params)
    message = build_message(%{sender: sender, text: text})

    assert Service.duplicate?(message) == true
  end

  test "duplicate?/1 returns false if a message with the same sender and text was received outside the last 5 minutes" do
    sender = "5555555555"
    text = "Test message"
    unix_now = DateTime.to_unix(DateTime.utc_now())
    over_five_minutes_ago = DateTime.from_unix!(unix_now - 301)
    params =
      %{sender: sender,
        text: text,
        timestamp: over_five_minutes_ago}
    Helpers.insert_recently_received_message(params)
    message = build_message(params)

    assert Service.duplicate?(message) == false
  end

  test "insert_recently_received_message/1 inserts a recently received message" do
    message = build_message()

    Service.insert_recently_received_message(message)

    recently_received_message = List.first(Storage.all(RecentlyReceivedMessage))
    assert recently_received_message.sender == message.sender
    assert recently_received_message.text == message.text
    assert recently_received_message.timestamp == message.timestamp
  end

  test "insert_command_history/1 inserts a command history entry" do
    message = build_message()

    Service.insert_command_history(message)

    command_history = List.first(Storage.all(CommandHistory))
    assert command_history.text == message.text
    assert command_history.timestamp == message.timestamp
  end

  test "not_yet_engaged_phones/0 returns the phone of every user with an active conversation who has yet to send a message" do
    sms_relay = Helpers.insert_sms_relay()
    engaged = Helpers.insert_user()
    not_yet_engaged1 = Helpers.insert_user()
    not_yet_engaged2 = Helpers.insert_user()
    not_yet_engaged3 = Helpers.insert_user()
    inactive1 = Helpers.insert_user()
    inactive2 = Helpers.insert_user()
    conversation = Helpers.insert_conversation(
      %{active?: true,
        iteration: 1,
        sms_relay_id: sms_relay.id,
        users: [engaged.id, not_yet_engaged1.id]})
    Helpers.insert_conversation(
      %{active?: true,
        iteration: 1,
        sms_relay_id: sms_relay.id,
        users: [not_yet_engaged2.id, not_yet_engaged3.id]})
    Helpers.insert_conversation(
      %{active?: false,
        iteration: 1,
        sms_relay_id: sms_relay.id,
        users: [inactive1.id, inactive2.id]})
    Helpers.insert_message(
      %{conversation_id: conversation.id,
        user_id: engaged.id})

    not_yet_engaged_phones = Service.not_yet_engaged_phones()

    assert length(not_yet_engaged_phones) == 3
    assert Enum.member?(not_yet_engaged_phones, not_yet_engaged1.phone)
    assert Enum.member?(not_yet_engaged_phones, not_yet_engaged2.phone)
    assert Enum.member?(not_yet_engaged_phones, not_yet_engaged3.phone)
    assert !Enum.member?(not_yet_engaged_phones, engaged.phone)
    assert !Enum.member?(not_yet_engaged_phones, inactive1.phone)
    assert !Enum.member?(not_yet_engaged_phones, inactive2.phone)
  end
end
