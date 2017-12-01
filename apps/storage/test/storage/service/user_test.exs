defmodule Storage.Service.UserTest do
  use ExUnit.Case

  alias Ecto.Adapters.SQL.Sandbox

  alias Storage.{Conversation, Helpers, Message, User}
  alias Storage.Service.User, as: UserService

  setup do
    :ok = Sandbox.checkout(Storage)
    Sandbox.mode(Storage, {:shared, self()})
  end

  test "by_phone/1 fetches a user by phone" do
    user = Helpers.insert_user()
    Helpers.insert_user()

    assert UserService.by_phone(user.phone) == user
  end

  test "all/0 returns every user" do
    user1 = Helpers.insert_user()
    user2 = Helpers.insert_user()

    users = UserService.all()

    assert length(users) == 2
    assert Enum.member?(users, user1)
    assert Enum.member?(users, user2)
  end

  test "all_enabled/0 returns all users who have completed the tutorial" do
    Helpers.insert_user(%{tutorial_step: 0})
    Helpers.insert_user(%{tutorial_step: 0})
    Helpers.insert_user(%{tutorial_step: 1})
    Helpers.insert_user(%{tutorial_step: 2})
    Helpers.insert_user(%{tutorial_step: 3})
    Helpers.insert_user(%{tutorial_step: 4})
    Helpers.insert_user(%{tutorial_step: 5})

    assert length(UserService.all_enabled()) == 2
  end

  test "name/1 returns the user's name" do
    user = Helpers.insert_user()

    assert UserService.name(user.phone) == user.name
  end

  test "insert_user/2 inserts a user" do
    name = "Test User"
    phone = "5555555555"

    {:ok, _} = UserService.insert(name, phone)

    user = List.first(Storage.all(User))
    assert user.name == name
    assert user.phone == phone
    assert user.tutorial_step == 1
  end

  test "delete_user/1 deletes the user with the given phone, along with their messages and links to conversations" do
    user = Helpers.insert_user()
    partner = Helpers.insert_user()
    conversation = Helpers.insert_conversation(
      %{active?: true,
        iteration: 1,
        users: [user.id, partner.id]})
    user_message = Helpers.insert_message(
      %{conversation_id: conversation.id,
        user_id: user.id})
    partner_message = Helpers.insert_message(
      %{conversation_id: conversation.id,
        user_id: partner.id})

    UserService.delete(user.phone)

    assert Storage.get(User, user.id) == nil

    conversation = Storage.get(Conversation, conversation.id)
    conversation = Storage.preload(conversation, :users)
    assert length(conversation.users) == 1

    assert Storage.get(Message, user_message.id) == nil
    assert Storage.get(Message, partner_message.id) != nil
  end

  test "user?/1 returns true if a user with the given phone exists" do
    user = Helpers.insert_user()

    assert UserService.exists?(user.phone) == true
  end

  test "user?/1 returns false if no user with the given phone exists" do
    assert UserService.exists?("5555555555") == false
  end

  test "in_tutorial?/1 returns true if the user has not yet completed the tutorial" do
    user = Helpers.insert_user(%{tutorial_step: 1})

    assert UserService.in_tutorial?(user.phone) == true
  end

  test "in_tutorial?/1 returns false if the user has completed the tutorial" do
    user = Helpers.insert_user(%{tutorial_step: 0})

    assert UserService.in_tutorial?(user.phone) == false
  end

  test "tutorial_step/1 returns the tutorial step the user is on" do
    user = Helpers.insert_user(%{tutorial_step: 1})

    assert UserService.tutorial_step(user.phone) == 1
  end

  test "advance_tutorial/1 increments the tutorial step the user is on" do
    user = Helpers.insert_user(%{tutorial_step: 1})

    UserService.advance_tutorial(user.phone)

    assert UserService.tutorial_step(user.phone) == 2
  end

  test "advance_tutorial/1 sets the user's tutorial step to 0 when their current step is 5" do
    user = Helpers.insert_user(%{tutorial_step: 5})

    UserService.advance_tutorial(user.phone)

    assert UserService.tutorial_step(user.phone) == 0
  end

  test "update_engagement_level/2 updates the user's engagement level" do
    user = Helpers.insert_user(%{engagement_level: -1})

    UserService.update_engagement_level(user, 5)

    user = Storage.get(User, user.id)
    assert user.engagement_level == 5
  end
end
