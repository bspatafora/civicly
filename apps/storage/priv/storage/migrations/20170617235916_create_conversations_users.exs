defmodule Storage.Migrations.CreateConversationsUsers do
  use Ecto.Migration

  def change do
    drop constraint(:conversations, :one_per_user_per_time)

    alter table(:conversations) do
      remove :left_user_id
      remove :right_user_id

      remove :start
      add :iteration, :integer, null: false
    end

    create table(:conversations_users, primary_key: false) do
      add :conversation_id, references(:conversations), null: false
      add :user_id, references(:users), null: false
    end
  end
end
