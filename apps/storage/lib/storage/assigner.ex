defmodule Storage.Assigner do
  @moduledoc false

  alias Storage.{Conversation, User}

  def assign_all do
    start = DateTime.utc_now

    users = Storage.all(User)
    {leftover_user, users} = pop_ben(users)

    users
    |> Enum.shuffle
    |> Enum.chunk(2, 2, [leftover_user])
    |> Enum.each(fn(pair) -> insert_conversation(pair, start) end)
  end

  defp pop_ben(users) do
    phone = get_config(:ben_phone)
    index = Enum.find_index(users, fn(u) -> u.phone == phone end)

    List.pop_at(users, index)
  end

  defp insert_conversation(user_pair, start) do
    params =
      %{left_user_id: List.first(user_pair).id,
        right_user_id: List.last(user_pair).id,
        proxy_phone: get_config(:proxy_phone),
        start: start}

    changeset = Conversation.changeset(%Conversation{}, params)
    Storage.insert!(changeset)
  end

  defp get_config(key) do
    Application.get_env(:storage, key)
  end
end
