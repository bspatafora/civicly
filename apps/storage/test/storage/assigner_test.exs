defmodule Storage.AssignerTest do
  use ExUnit.Case

  alias Ecto.Adapters.SQL.Sandbox
  alias Storage.{Assigner, Conversation, User}

  @ben_phone Application.get_env(:storage, :ben_phone)
  @proxy_phone Application.get_env(:storage, :proxy_phone)

  setup do
    :ok = Sandbox.checkout(Storage)
    Sandbox.mode(Storage, {:shared, self()})
  end

  def insert_user(phone \\ Helpers.random_phone) do
    params = %{name: "Test User", phone: phone}

    changeset = User.changeset(%User{}, params)
    {:ok, user} = Storage.insert(changeset)
    user
  end

  test "assign_all/0 assigns all users to conversations" do
    user_ids = MapSet.new(
      [insert_user(@ben_phone).id,
       insert_user().id,
       insert_user().id,
       insert_user().id])

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
    insert_user(@ben_phone)
    other_user_ids = MapSet.new(
      [insert_user().id,
       insert_user().id])

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
    insert_user(@ben_phone)
    insert_user()

    Assigner.assign_all()

    conversations = Storage.all(Conversation)
    start_times = conversations
                  |> Enum.map(fn(c) -> c.start end)
    first_start_time = List.first(start_times)

    assert %DateTime{} = first_start_time
    assert Enum.all?(start_times, fn(t) -> t == first_start_time end)
  end

  test "assign_all/0 assigns all users the configured proxy phone" do
    insert_user(@ben_phone)
    insert_user()

    Assigner.assign_all()

    conversations = Storage.all(Conversation)
    proxy_phones = conversations
                   |> Enum.map(fn(c) -> c.proxy_phone end)

    assert Enum.all?(proxy_phones, fn(p) -> p == @proxy_phone end)
  end
end
