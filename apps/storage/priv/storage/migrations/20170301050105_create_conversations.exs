defmodule Storage.Migrations.CreateConversations do
  use Ecto.Migration

  def change do
    create table(:conversations) do
      add :left_user_id, references(:users), null: false
      add :right_user_id, references(:users), null: false
      add :proxy_phone, :string, null: false, size: 10
      add :start, :utc_datetime, null: false

      timestamps([type: :utc_datetime])
    end

    execute "CREATE EXTENSION IF NOT EXISTS btree_gist"
    execute "CREATE EXTENSION IF NOT EXISTS intarray"

    create constraint(:conversations, :different_user_ids, check: "left_user_id <> right_user_id")

    alter table(:users) do
      remove :partner_id

      remove :inserted_at
      remove :updated_at
      timestamps([type: :utc_datetime])
    end
  end
end
