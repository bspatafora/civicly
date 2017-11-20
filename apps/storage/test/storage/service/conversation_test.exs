defmodule Storage.Service.ConversationTest do
  use ExUnit.Case

  alias Ecto.Adapters.SQL.Sandbox

  alias Storage.{Helpers, Conversation}
  alias Storage.Service.Conversation, as: ConversationService

  setup do
    :ok = Sandbox.checkout(Storage)
    Sandbox.mode(Storage, {:shared, self()})
  end

  test "all_active/0 returns every active conversation" do
    active = Helpers.insert_conversation(%{active?: true})
    Helpers.insert_conversation(%{active?: false})

    all_active = ConversationService.all_active()

    assert length(all_active) == 1
    assert List.first(all_active).id == active.id
  end

  test "all_current/0 fetches the conversations for the current iteration" do
    not_current = Helpers.insert_conversation(%{iteration: 1})
    current1 = Helpers.insert_conversation(%{iteration: 2})
    current2 = Helpers.insert_conversation(%{iteration: 2})

    conversations = ConversationService.all_current()

    assert length(conversations) == 2
    assert Enum.member?(conversations, current1)
    assert Enum.member?(conversations, current2)
    assert !Enum.member?(conversations, not_current)
  end

  test "insert/3 inserts a conversation and gives it an inactive status" do
    sms_relay = Helpers.insert_sms_relay()
    iteration = 1
    users = [Helpers.insert_user(), Helpers.insert_user()]

    conversation = ConversationService.insert(iteration, sms_relay.id, users)

    assert conversation.active? == false
    assert conversation.iteration == iteration
    assert conversation.sms_relay_id == sms_relay.id
    assert conversation.users == users
  end

  test "current_iteration/0 fetches the current iteration" do
    assert ConversationService.current_iteration() == nil

    Helpers.insert_conversation(%{iteration: 1})

    assert ConversationService.current_iteration() == 1
  end

  test "partner_phones/2 returns the phones of the conversation's other users" do
    user = Helpers.insert_user()
    partner1 = Helpers.insert_user()
    partner2 = Helpers.insert_user()
    conversation = Helpers.insert_conversation(
      %{users: [user.id, partner1.id, partner2.id]})

    partner_phones = ConversationService.partner_phones(user.phone, conversation)

    assert length(partner_phones) == 2
    assert Enum.member?(partner_phones, partner1.phone) == true
    assert Enum.member?(partner_phones, partner2.phone) == true
  end

  test "active?/1 returns the status of the conversation" do
    active = Helpers.insert_conversation(%{active?: true})
    inactive = Helpers.insert_conversation(%{active?: false})

    assert ConversationService.active?(active) == true
    assert ConversationService.active?(inactive) == false
  end

  test "inactivate_all/0 sets the status of all conversations to inactive" do
    first = Helpers.insert_conversation(%{active?: true})
    second = Helpers.insert_conversation(%{active?: true})

    ConversationService.inactivate_all()

    [first, second]
      |> Enum.each(&(Storage.get(Conversation, &1.id).active? == false))
  end

  test "activate/1 sets the conversation's status to active" do
    conversation = Helpers.insert_conversation(%{active?: false})

    ConversationService.activate(conversation)

    conversation = Storage.get(Conversation, conversation.id)
    assert conversation.active? == true
  end

  test "inactivate/1 sets the conversation's status to inactive" do
    conversation = Helpers.insert_conversation(%{active?: true})

    ConversationService.inactivate(conversation)

    conversation = Storage.get(Conversation, conversation.id)
    assert conversation.active? == false
  end
end