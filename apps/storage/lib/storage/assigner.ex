defmodule Storage.Assigner do
  @moduledoc false

  import Ecto.Query

  alias Storage.{Conversation, SMSRelay, User}

  def assign_all do
    start = DateTime.utc_now
    first_sms_relay = SMSRelay |> first |> Storage.one

    users = Storage.all(User)
    {leftover_user, users} = pop_ben(users)

    users
    |> Enum.shuffle
    |> Enum.chunk(2, 2, [leftover_user])
    |> Enum.each(fn(pair) -> insert_conversation(pair, start, first_sms_relay.id) end)
  end

  defp pop_ben(users) do
    phone = get_config(:ben_phone)
    index = Enum.find_index(users, fn(u) -> u.phone == phone end)

    List.pop_at(users, index)
  end

  defp insert_conversation(user_pair, start, sms_relay_id) do
    params =
      %{left_user_id: List.first(user_pair).id,
        right_user_id: List.last(user_pair).id,
        sms_relay_id: sms_relay_id,
        start: start}

    changeset = Conversation.changeset(%Conversation{}, params)
    Storage.insert!(changeset)
  end

  defp get_config(key) do
    Application.get_env(:storage, key)
  end
end
