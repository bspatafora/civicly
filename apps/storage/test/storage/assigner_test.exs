defmodule Storage.AssignerTest do
  use ExUnit.Case

  alias Ecto.Adapters.SQL.Sandbox
  alias Storage.{Assigner, Conversation, Helpers}

  @ben_phone Application.get_env(:storage, :ben_phone)

  setup do
    :ok = Sandbox.checkout(Storage)
    Sandbox.mode(Storage, {:shared, self()})
  end

  test "assign_all/0 assigns all users to conversations" do
    Helpers.insert_sms_relay()

    user_ids = MapSet.new(
      [Helpers.insert_user(@ben_phone).id,
       Helpers.insert_user().id,
       Helpers.insert_user().id,
       Helpers.insert_user().id])

    Assigner.assign_all()

    conversations = Storage.all(Conversation)
    get_user_ids = fn(c) -> [c.left_user_id, c.right_user_id] end
    conversation_user_ids = conversations
                            |> Enum.flat_map(get_user_ids)
                            |> MapSet.new

    assert length(conversations) == 2
    assert MapSet.equal?(user_ids, conversation_user_ids)
  end

  test "assign_all/0 leaves Ben out when there is an odd number of users" do
    Helpers.insert_sms_relay()

    Helpers.insert_user(@ben_phone)
    other_user_ids = MapSet.new(
      [Helpers.insert_user().id,
       Helpers.insert_user().id])

    Assigner.assign_all()

    conversations = Storage.all(Conversation)
    get_user_ids = fn(c) -> [c.left_user_id, c.right_user_id] end
    conversation_user_ids = conversations
                            |> Enum.flat_map(get_user_ids)
                            |> MapSet.new

    assert length(conversations) == 1
    assert MapSet.equal?(other_user_ids, conversation_user_ids)
  end

  test "assign_all/0 assigns all users the same start time" do
    Helpers.insert_sms_relay()

    Helpers.insert_user(@ben_phone)
    Helpers.insert_user()

    Assigner.assign_all()

    conversations = Storage.all(Conversation)
    start_times = conversations
                  |> Enum.map(fn(c) -> c.start end)
    first_start_time = List.first(start_times)

    assert %DateTime{} = first_start_time
    assert Enum.all?(start_times, fn(t) -> t == first_start_time end)
  end

  test "assign_all/0 assigns all users the first SMS relay in the database" do
    sms_relay = Helpers.insert_sms_relay()

    Helpers.insert_user(@ben_phone)
    Helpers.insert_user()

    Assigner.assign_all()

    conversations = Storage.all(Conversation)
    sms_relay_ids = conversations
                    |> Enum.map(fn(c) -> c.sms_relay_id end)

    assert Enum.all?(sms_relay_ids, fn(p) -> p == sms_relay.id end)
  end
end
