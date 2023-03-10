defmodule Iteration.AssignerTest do
  use ExUnit.Case

  alias Ecto.Adapters.SQL.Sandbox

  alias Iteration.Assigner
  alias Storage.{Conversation, Helpers, User}

  @ben_phone Application.get_env(:storage, :ben_phone)

  setup do
    :ok = Sandbox.checkout(Storage)
    Sandbox.mode(Storage, {:shared, self()})
  end

  test "group_by_twos/0 assigns each active user to a two-person conversation" do
    Helpers.insert_sms_relay()
    Helpers.insert_user(%{tutorial_step: 1})
    Helpers.insert_user(%{tutorial_step: 1})
    active_user_ids =
      [Helpers.insert_user(%{phone: @ben_phone}).id,
       Helpers.insert_user().id,
       Helpers.insert_user().id,
       Helpers.insert_user().id]

    Assigner.group_by_twos()

    conversations = Storage.all(Conversation)
    conversation_user_ids = conversations
                            |> Storage.preload(:users)
                            |> Enum.flat_map(&(&1.users))
                            |> Enum.map(&(&1.id))

    assert length(conversations) == 2
    assert active_user_ids -- conversation_user_ids == []
  end

  test "group_by_twos/0 leaves Ben out when there is an odd number of users" do
    Helpers.insert_sms_relay()
    Helpers.insert_user(%{phone: @ben_phone})
    other_user_ids = [Helpers.insert_user().id, Helpers.insert_user().id]

    Assigner.group_by_twos()

    conversations = Storage.all(Conversation)
    conversation_user_ids = conversations
                            |> Storage.preload(:users)
                            |> Enum.flat_map(&(&1.users))
                            |> Enum.map(&(&1.id))

    assert length(conversations) == 1
    assert other_user_ids -- conversation_user_ids == []
  end

  test "group_by_twos/0 assigns all users the same iteration" do
    Helpers.insert_sms_relay()
    Helpers.insert_user(%{phone: @ben_phone})
    Helpers.insert_user()
    Helpers.insert_user()
    Helpers.insert_user()

    Assigner.group_by_twos()

    conversations = Storage.all(Conversation)
    iterations = conversations |> Enum.map(&(&1.iteration))

    assert Enum.all?(iterations, &(&1 == 1))
  end

  test "group_by_twos/0 increments the iteration on each run" do
    Helpers.insert_sms_relay()
    Helpers.insert_user(%{phone: @ben_phone})
    Helpers.insert_user()

    Assigner.group_by_twos()
    Assigner.group_by_twos()

    conversations = Storage.all(Conversation)
    iterations = conversations |> Enum.map(&(&1.iteration))

    assert Enum.member?(iterations, 1)
    assert Enum.member?(iterations, 2)
  end

  test "group_by_twos/0 assigns all users the first SMS relay in the database" do
    sms_relay = Helpers.insert_sms_relay()
    Helpers.insert_user(%{phone: @ben_phone})
    Helpers.insert_user()
    Helpers.insert_user()
    Helpers.insert_user()

    Assigner.group_by_twos()

    conversations = Storage.all(Conversation)
    sms_relay_ids = conversations |> Enum.map(&(&1.sms_relay_id))

    assert Enum.all?(sms_relay_ids, &(&1 == sms_relay.id))
  end

  test "group_by_threes/0 assigns each active user to a three-person conversation" do
    Helpers.insert_sms_relay()
    Helpers.insert_user(%{tutorial_step: 1})
    Helpers.insert_user(%{tutorial_step: 1})
    Helpers.insert_user(%{tutorial_step: 1})
    active_user_ids =
      [Helpers.insert_user(%{phone: @ben_phone}).id,
       Helpers.insert_user().id,
       Helpers.insert_user().id,
       Helpers.insert_user().id,
       Helpers.insert_user().id,
       Helpers.insert_user().id]

    Assigner.group_by_threes()

    conversations = Storage.all(Conversation)
    conversation_user_ids = conversations
                            |> Storage.preload(:users)
                            |> Enum.flat_map(&(&1.users))
                            |> Enum.map(&(&1.id))

    assert length(conversations) == 2
    assert active_user_ids -- conversation_user_ids == []
  end

  test "group_by_threes/0 leaves Ben out when there is one leftover user" do
    Helpers.insert_sms_relay()
    Helpers.insert_user(%{phone: @ben_phone})
    other_user_ids =
      [Helpers.insert_user().id,
       Helpers.insert_user().id,
       Helpers.insert_user().id]

    Assigner.group_by_threes()

    conversations = Storage.all(Conversation)
    conversation_user_ids = conversations
                            |> Storage.preload(:users)
                            |> Enum.flat_map(&(&1.users))
                            |> Enum.map(&(&1.id))

    assert length(conversations) == 1
    assert other_user_ids -- conversation_user_ids == []
  end

  test "group_by_threes/0 includes Ben in two conversations when there are two leftover users" do
    Helpers.insert_sms_relay()
    ben = Helpers.insert_user(%{phone: @ben_phone})
    other_user_ids =
      [Helpers.insert_user().id,
       Helpers.insert_user().id,
       Helpers.insert_user().id,
       Helpers.insert_user().id]

    Assigner.group_by_threes()

    conversations = Storage.all(Conversation)
    conversations = Storage.preload(conversations, :users)
    conversation_user_ids = conversations
                            |> Enum.flat_map(&(&1.users))
                            |> Enum.map(&(&1.id))

    ben = Storage.get(User, ben.id)
    assert length(conversations) == 2
    assert conversation_user_ids -- other_user_ids == [ben.id, ben.id]
    assert Enum.member?(List.first(conversations).users, ben)
    assert Enum.member?(List.last(conversations).users, ben)
  end

  test "group_by_threes/0 assigns all users the same iteration" do
    Helpers.insert_sms_relay()
    Helpers.insert_user(%{phone: @ben_phone})
    Helpers.insert_user()
    Helpers.insert_user()
    Helpers.insert_user()
    Helpers.insert_user()
    Helpers.insert_user()

    Assigner.group_by_threes()

    conversations = Storage.all(Conversation)
    iterations = conversations |> Enum.map(&(&1.iteration))

    assert Enum.all?(iterations, &(&1 == 1))
  end

  test "group_by_threes/0 increments the iteration on each run" do
    Helpers.insert_sms_relay()
    Helpers.insert_user(%{phone: @ben_phone})
    Helpers.insert_user()
    Helpers.insert_user()

    Assigner.group_by_threes()
    Assigner.group_by_threes()

    conversations = Storage.all(Conversation)
    iterations = conversations |> Enum.map(&(&1.iteration))

    iterations = Enum.sort(iterations)
    assert List.first(iterations) == 1
    assert List.last(iterations) == 2
  end

  test "group_by_threes/0 assigns all users the first SMS relay in the database" do
    sms_relay = Helpers.insert_sms_relay()
    Helpers.insert_user(%{phone: @ben_phone})
    Helpers.insert_user()
    Helpers.insert_user()
    Helpers.insert_user()
    Helpers.insert_user()
    Helpers.insert_user()

    Assigner.group_by_threes()

    conversations = Storage.all(Conversation)
    sms_relay_ids = conversations |> Enum.map(&(&1.sms_relay_id))

    assert Enum.all?(sms_relay_ids, &(&1 == sms_relay.id))
  end
end
