defmodule Storage.Assigner do
  @moduledoc false

  import Ecto.Query

  alias Storage.{Conversation, SMSRelay, User}

  def group_by_threes do
    group(&by_threes/2)
  end

  def group_by_twos do
    group(&by_twos/2)
  end

  defp group(group_strategy) do
    iteration = current_iteration()
    sms_relay_id = sms_relay_id()
    {flexible_user, users} = pop_ben(Storage.all(User))

    users
    |> Enum.shuffle
    |> group_strategy.(flexible_user)
    |> Enum.each(&(insert_conversation(iteration, sms_relay_id, &1)))
  end

  defp current_iteration do
    query = from c in Conversation, select: max(c.iteration)
    last_iteration = Storage.one(query)

    case last_iteration do
      nil -> 1
      iteration -> iteration + 1
    end
  end

  defp sms_relay_id do
    first_sms_relay = SMSRelay |> first |> Storage.one
    first_sms_relay.id
  end

  defp pop_ben(users) do
    phone = Application.get_env(:storage, :ben_phone)
    index = Enum.find_index(users, &(&1.phone == phone))

    List.pop_at(users, index)
  end

  defp by_threes(users, flexible_user) do
    user_count = length(users) + 1

    case rem(user_count, 3) do
      2 ->
        {users, last_four_users} = Enum.split(users, -4)
        groups = Enum.chunk(users, 3)

        penultimate_group = Enum.slice(last_four_users, 0..1) ++ [flexible_user]
        ultimate_group = Enum.slice(last_four_users, 2..3) ++ [flexible_user]
        groups ++ [penultimate_group, ultimate_group]
      _ ->
        Enum.chunk(users, 3, 3, [flexible_user])
    end
  end

  defp by_twos(users, flexible_user) do
    Enum.chunk(users, 2, 2, [flexible_user])
  end

  defp insert_conversation(iteration, sms_relay_id, users) do
    params =
      %{iteration: iteration,
        sms_relay_id: sms_relay_id,
        users: Enum.map(users, &(&1.id))}

    changeset = Conversation.changeset(%Conversation{}, params)
    Storage.insert!(changeset)
  end
end
