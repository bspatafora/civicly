defmodule Storage.Migrations.BackfillActivatedAtsOnConversations do
  use Ecto.Migration

  alias Storage.Conversation

  def up do
    conversations = Storage.all(Conversation)
    conversations = Storage.preload(conversations, :users)
    to_backfill = Enum.filter(conversations, &(&1.activated_at == nil))

    Enum.each(to_backfill, fn conversation ->
      three_hours = 10800
      inserted_at_unix = DateTime.to_unix(conversation.inserted_at)
      activated_at_unix = inserted_at_unix + three_hours
      activated_at = DateTime.from_unix!(activated_at_unix)

      params =
        %{activated_at: activated_at,
          users: Enum.map(conversation.users, &(&1.id))}

      conversation
        |> Conversation.changeset(params)
        |> Storage.update!
    end)
  end

  def down do
  end
end
