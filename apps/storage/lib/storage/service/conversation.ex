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
    set_status(conversation, true)
  end

  def inactivate(conversation) do
    set_status(conversation, false)
  end

  defp set_status(conversation, status) do
    conversation = Storage.preload(conversation, :users)
    params =
      %{active?: status,
        users: Enum.map(conversation.users, &(&1.id))}

    conversation
      |> Conversation.changeset(params)
      |> Storage.update!
  end
end