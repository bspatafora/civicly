defmodule Storage.EngagementServiceTest do
  use ExUnit.Case
  use Timex

  alias Ecto.Adapters.SQL.Sandbox

  alias Storage.{EngagementLevelService, Helpers, User}

  setup do
    :ok = Sandbox.checkout(Storage)
    Sandbox.mode(Storage, {:shared, self()})
  end

  test "update_all/0 sets a user's engagement level to -1 when they've had fewer than 5 conversations" do
    user = Helpers.insert_user()
    for _ <- 1..4 do
      Helpers.insert_conversation(
        %{activated_at: DateTime.utc_now(),
          users: [user.id, Helpers.insert_user().id]})
    end

    EngagementLevelService.update_all()

    user = Storage.get(User, user.id)
    assert user.engagement_level == -1
  end

  test "update_all/0 doesn't count conversations that haven't been activated yet" do
    user = Helpers.insert_user()
    for _ <- 1..5 do
      Helpers.insert_conversation(
        %{activated_at: nil,
          users: [user.id, Helpers.insert_user().id]})
    end

    EngagementLevelService.update_all()

    user = Storage.get(User, user.id)
    assert user.engagement_level == -1
  end

  test "update_all/0 sets a user's engagement level to 0 when they didn't send a message in any of their 5 most recent conversations" do
    user = Helpers.insert_user()
    for _ <- 1..5 do
      Helpers.insert_conversation(
        %{activated_at: DateTime.utc_now(),
          users: [user.id, Helpers.insert_user().id]})
    end

    EngagementLevelService.update_all()

    user = Storage.get(User, user.id)
    assert user.engagement_level == 0
  end

  test "update_all/0 sets a user's engagement level to 0 when they didn't send a message within 24 hours of start in any of their 5 most recent conversations" do
    activated_at = Timex.shift(Timex.now(), days: -4)
    one_day_later = Timex.shift(activated_at, days: 1)

    user = Helpers.insert_user()
    for _ <- 1..5 do
      conversation = Helpers.insert_conversation(
        %{activated_at: activated_at,
          users: [user.id, Helpers.insert_user().id]})

      Helpers.insert_message(
        %{conversation_id: conversation.id,
          timestamp: one_day_later,
          user_id: user.id})
    end

    EngagementLevelService.update_all()

    user = Storage.get(User, user.id)
    assert user.engagement_level == 0
  end

  test "update_all/0 sets a user's engagement level based on the number of their last 5 conversations where they sent a message within 24 hours of start" do
    activated_at = Timex.shift(Timex.now(), days: -4)
    one_day_later = Timex.shift(activated_at, days: 1)
    not_quite_one_day_later = Timex.shift(activated_at, hours: 23, minutes: 59)

    user = Helpers.insert_user()

    for _ <- 1..3 do
      conversation = Helpers.insert_conversation(
        %{activated_at: activated_at,
          users: [user.id, Helpers.insert_user().id]})

      Helpers.insert_message(
        %{conversation_id: conversation.id,
          timestamp: not_quite_one_day_later,
          user_id: user.id})
    end

    for _ <- 1..2 do
      conversation = Helpers.insert_conversation(
        %{activated_at: activated_at,
          users: [user.id, Helpers.insert_user().id]})

      Helpers.insert_message(
        %{conversation_id: conversation.id,
          timestamp: one_day_later,
          user_id: user.id})
    end

    EngagementLevelService.update_all()

    user = Storage.get(User, user.id)
    assert user.engagement_level == 3
  end

  test "update_all/0 only considers the user's messages, not their partner's" do
    activated_at = Timex.shift(Timex.now(), days: -4)
    one_day_later = Timex.shift(activated_at, days: 1)
    not_quite_one_day_later = Timex.shift(activated_at, hours: 23, minutes: 59)

    user1 = Helpers.insert_user()
    user2 = Helpers.insert_user()
    for _ <- 1..4 do
      Helpers.insert_conversation(
        %{activated_at: activated_at,
          users: [user1.id, user2.id]})
    end

    conversation_with_messages = Helpers.insert_conversation(
      %{activated_at: activated_at,
        users: [user1.id, user2.id]})
    Helpers.insert_message(
      %{conversation_id: conversation_with_messages.id,
        timestamp: one_day_later,
        user_id: user1.id})
    Helpers.insert_message(
      %{conversation_id: conversation_with_messages.id,
        timestamp: not_quite_one_day_later,
        user_id: user2.id})

    EngagementLevelService.update_all()

    user1 = Storage.get(User, user1.id)
    user2 = Storage.get(User, user2.id)
    assert user1.engagement_level == 0
    assert user2.engagement_level == 1
  end

  test "update_all/0 only considers the user's earliest message in a given conversation" do
    activated_at = Timex.shift(Timex.now(), days: -4)
    one_day_later = Timex.shift(activated_at, days: 1)
    not_quite_one_day_later = Timex.shift(activated_at, hours: 23, minutes: 59)

    user = Helpers.insert_user()
    for _ <- 1..4 do
      Helpers.insert_conversation(
        %{activated_at: activated_at,
          users: [user.id, Helpers.insert_user().id]})
    end

    conversation_with_messages = Helpers.insert_conversation(
      %{activated_at: activated_at,
        users: [user.id, Helpers.insert_user().id]})
    Helpers.insert_message(
      %{conversation_id: conversation_with_messages.id,
        timestamp: not_quite_one_day_later,
        user_id: user.id})
    Helpers.insert_message(
      %{conversation_id: conversation_with_messages.id,
        timestamp: one_day_later,
        user_id: user.id})

    EngagementLevelService.update_all()

    user = Storage.get(User, user.id)
    assert user.engagement_level == 1
  end
end
