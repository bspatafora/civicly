defmodule Storage.Migrations.AddOnDeletes do
  use Ecto.Migration

  def up do
    drop constraint(:conversations_users, "conversations_users_conversation_id_fkey")
    alter table(:conversations_users) do
      modify :conversation_id, references(:conversations, on_delete: :delete_all)
    end

    drop constraint(:messages, "messages_conversation_id_fkey")
    alter table(:messages) do
      modify :conversation_id, references(:conversations, on_delete: :delete_all), null: false
    end
  end

  def down do
    drop constraint(:conversations_users, "conversations_users_conversation_id_fkey")
    alter table(:conversations_users) do
      modify :conversation_id, references(:conversations)
    end

    drop constraint(:messages, "messages_conversation_id_fkey")
    alter table(:messages) do
      modify :conversation_id, references(:conversations), null: false
    end
  end
end
