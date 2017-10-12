defmodule Storage.Migrations.CreateConversationsUsers do
  use Ecto.Migration

  def change do
    alter table(:conversations) do
      remove :left_user_id
      remove :right_user_id

      remove :start
      add :iteration, :integer, null: false
    end

    create table(:conversations_users, primary_key: false) do
      add :conversation_id, references(:conversations)
      add :user_id, references(:users, on_delete: :delete_all)
    end
  end
end
