defmodule Storage.EngagementLevelService do
  @moduledoc false

  @one_day 86_400

  alias Storage.Service.{Conversation, User}

  def update_all do
    Enum.each(User.all(), &(update(&1)))
  end

  defp update(user) do
    conversations = Conversation.latest_by_user(user.id, 5)

    activation_timestamps = conversations
      |> Enum.map(&(&1.activated_at))

    message_groups = conversations
      |> Enum.map(&Storage.preload(&1, :messages))
      |> Enum.map(&(&1.messages))

    first_user_message_timestamp_and_activation_timestamp_tuples = message_groups
      |> Enum.map(&limit_to_user_messages(&1, user.id))
      |> Enum.map(&limit_to_first_message(&1))
      |> Enum.map(&to_timestamps(&1))
      |> Enum.zip(activation_timestamps)

    engagement_values = first_user_message_timestamp_and_activation_timestamp_tuples
      |> Enum.map(&to_engagement_value(&1))

    new_user = length(engagement_values) < 5
    engaged_count = Enum.count(engagement_values, &(&1 == true))

    engagement_level = if new_user, do: -1, else: engaged_count

    User.update_engagement_level(user, engagement_level)
  end

  defp limit_to_user_messages(messages, user_id) do
    Enum.filter(messages, &(&1.user_id == user_id))
  end

  defp limit_to_first_message(messages) do
    datetime_comparison = fn (a, b) -> DateTime.compare(a.timestamp, b.timestamp) == :lt end

    messages
      |> Enum.sort(&datetime_comparison.(&1, &2))
      |> Enum.take(1)
  end

  defp to_timestamps(messages) do
    Enum.map(messages, &(&1.timestamp))
  end

  defp to_engagement_value(tuple) do
    first_user_message_timestamp? = elem(tuple, 0)
    user_sent_no_messages = Enum.empty?(first_user_message_timestamp?)

    if user_sent_no_messages do
      false
    else
      first_user_message_timestamp = List.first(first_user_message_timestamp?)
      activation_timestamp = elem(tuple, 1)

      time_to_first_message =
        DateTime.diff(first_user_message_timestamp, activation_timestamp)

      time_to_first_message < @one_day
    end
  end
end
