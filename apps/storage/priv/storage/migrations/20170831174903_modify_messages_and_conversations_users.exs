defmodule Storage.Migrations.ModifyMessagesAndConversationsUsers do
  use Ecto.Migration

  def up do
    execute "ALTER TABLE conversations_users DROP CONSTRAINT conversations_users_conversation_id_fkey"
    execute "ALTER TABLE conversations_users DROP CONSTRAINT conversations_users_user_id_fkey"
    alter table(:conversations_users) do
      modify :conversation_id, references(:conversations), null: false
      modify :user_id, references(:users, on_delete: :delete_all), null: false
    end

    execute "ALTER TABLE messages DROP CONSTRAINT messages_user_id_fkey"
    alter table(:messages) do
      modify :user_id, references(:users, on_delete: :delete_all), null: false
    end
  end

  def down do
    execute "ALTER TABLE conversations_users DROP CONSTRAINT conversations_users_conversation_id_fkey"
    execute "ALTER TABLE conversations_users DROP CONSTRAINT conversations_users_user_id_fkey"
    alter table(:conversations_users) do
      modify :conversation_id, references(:conversations)
      modify :user_id, references(:users, on_delete: :delete_all)
    end

    execute "ALTER TABLE messages DROP CONSTRAINT messages_user_id_fkey"
    alter table(:messages) do
      modify :user_id, references(:users, on_delete: :nothing), null: false
    end
  end
end
