defmodule Storage.ServiceTest do
  use ExUnit.Case

  alias Ecto.Adapters.SQL.Sandbox

  alias Storage.{Helpers, Message, Service}

  setup do
    :ok = Sandbox.checkout(Storage)
    Sandbox.mode(Storage, {:shared, self()})
  end

  test "partner_phones/1 provides the partner phones for a user's current conversation" do
    user = Helpers.insert_user()
    old_partner = Helpers.insert_user()
    current_partner = Helpers.insert_user()
    Helpers.insert_conversation(
      %{active?: false,
        iteration: 1,
        users: [user.id, old_partner.id]})
    Helpers.insert_conversation(
      %{active?: true,
        iteration: 2,
        users: [user.id, current_partner.id]})

    partner_phones = Service.partner_phones(user.phone)

    assert length(partner_phones) == 1
    assert Enum.member?(partner_phones, current_partner.phone)
  end

  test "store_message/1 stores a message in the user's current conversation" do
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
    message = Helpers.build_message(
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

  test "in_conversation?/1 returns false when the user's current conversation is inactive" do
    user = Helpers.insert_user()
    partner = Helpers.insert_user()
    Helpers.insert_conversation(
      %{active?: true,
        iteration: 1,
        users: [user.id, partner.id]})
    Helpers.insert_conversation(
      %{active?: false,
        iteration: 2,
        users: [user.id, partner.id]})

    assert Service.in_conversation?(user.phone) == false
  end

  test "in_conversation?/1 returns false when the user has no conversations" do
    assert Service.in_conversation?(Helpers.insert_user().phone) == false
  end

  test "in_conversation?/1 returns true when the user's current conversation is active" do
    user = Helpers.insert_user()
    partner = Helpers.insert_user()
    Helpers.insert_conversation(
      %{active?: false,
        iteration: 1,
        users: [user.id, partner.id]})
    Helpers.insert_conversation(
      %{active?: true,
        iteration: 2,
        users: [user.id, partner.id]})

    assert Service.in_conversation?(user.phone) == true
  end

  test "all_phones/0 returns the phone of every user" do
    user1 = Helpers.insert_user()
    user2 = Helpers.insert_user()

    all_phones = Service.all_phones()

    assert length(all_phones) == 2
    assert Enum.member?(all_phones, user1.phone)
    assert Enum.member?(all_phones, user2.phone)
  end

  test "active_users/0 returns every user with an active conversation" do
    active1 = Helpers.insert_user()
    active2 = Helpers.insert_user()
    inactive1 = Helpers.insert_user()
    inactive2 = Helpers.insert_user()
    new = Helpers.insert_user()
    Helpers.insert_conversation(
      %{active?: true,
        iteration: 1,
        users: [active1.id, active2.id]})
    Helpers.insert_conversation(
      %{active?: false,
        iteration: 1,
        users: [inactive1.id, inactive2.id]})

    active_users = Service.active_users()

    assert length(active_users) == 2
    assert Enum.member?(active_users, active1)
    assert Enum.member?(active_users, active2)
    assert !Enum.member?(active_users, inactive1)
    assert !Enum.member?(active_users, inactive2)
    assert !Enum.member?(active_users, new)
  end

  test "active_phones/0 returns the phone of every user with an active conversation" do
    active1 = Helpers.insert_user()
    active2 = Helpers.insert_user()
    inactive1 = Helpers.insert_user()
    inactive2 = Helpers.insert_user()
    new = Helpers.insert_user()
    Helpers.insert_conversation(
      %{active?: true,
        iteration: 1,
        users: [active1.id, active2.id]})
    Helpers.insert_conversation(
      %{active?: false,
        iteration: 1,
        users: [inactive1.id, inactive2.id]})

    active_phones = Service.active_phones()

    assert length(active_phones) == 2
    assert Enum.member?(active_phones, active1.phone)
    assert Enum.member?(active_phones, active2.phone)
    assert !Enum.member?(active_phones, inactive1.phone)
    assert !Enum.member?(active_phones, inactive2.phone)
    assert !Enum.member?(active_phones, new.phone)
  end

  test "not_yet_engaged_phones/0 returns the phone of every user with an active conversation who has yet to send a message" do
    engaged = Helpers.insert_user()
    not_yet_engaged1 = Helpers.insert_user()
    not_yet_engaged2 = Helpers.insert_user()
    not_yet_engaged3 = Helpers.insert_user()
    inactive1 = Helpers.insert_user()
    inactive2 = Helpers.insert_user()
    conversation = Helpers.insert_conversation(
      %{active?: true,
        iteration: 1,
        users: [engaged.id, not_yet_engaged1.id]})
    Helpers.insert_conversation(
      %{active?: true,
        iteration: 1,
        users: [not_yet_engaged2.id, not_yet_engaged3.id]})
    Helpers.insert_conversation(
      %{active?: false,
        iteration: 1,
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
