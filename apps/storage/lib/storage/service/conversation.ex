defmodule Storage.Service.Conversation do
  @moduledoc false

  import Ecto.Query

  alias Storage.Conversation

  def all_active do
    query = from Conversation,
              where: [active?: true],
              preload: [:users]
    Storage.all(query)
  end

  def all_current do
    query = from Conversation,
              where: [iteration: ^current_iteration()],
              preload: [:sms_relay, :users]
    Storage.all(query)
  end

  def insert(iteration, sms_relay_id, users) do
    params =
      %{active?: false,
        iteration: iteration,
        sms_relay_id: sms_relay_id,
        users: Enum.map(users, &(&1.id))}

    changeset = Conversation.changeset(%Conversation{}, params)
    Storage.insert!(changeset)
  end

  def current_iteration do
    query = from c in Conversation, select: max(c.iteration)
    Storage.one(query)
  end

  def partner_phones(phone, conversation) do
    conversation = Storage.preload(conversation, :users)

    conversation.users
      |> Enum.map(&(&1.phone))
      |> Enum.reject(&(&1 == phone))
  end

  def active?(conversation) do
    conversation.active?
  end

  def inactivate_all do
    Storage.update_all(Conversation, set: [active?: false])
  end

  def activate(conversation) do
    params =
      %{activated_at: DateTime.utc_now(),
        active?: true}

    update_status(conversation, params)
  end

  def inactivate(conversation) do
    params =
      %{active?: false}

    update_status(conversation, params)
  end

  def latest_by_user(user_id, count) do
    query = from c in Conversation,
              join: cu in "conversations_users",
              on: cu.conversation_id == c.id,
              where: cu.user_id == ^user_id
              and not(is_nil(c.activated_at)),
              order_by: [desc: c.iteration],
              limit: ^count
    Storage.all(query)
  end

  defp update_status(conversation, params) do
    conversation = Storage.preload(conversation, :users)
    params = Map.merge(params, %{users: Enum.map(conversation.users, &(&1.id))})

    conversation
      |> Conversation.changeset(params)
      |> Storage.update!
  end
end
