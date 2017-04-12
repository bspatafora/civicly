defmodule Storage.Migrations.CreateMessages do
  use Ecto.Migration

  def change do
    create table(:messages) do
      add :conversation_id, references(:conversations), null: false
      add :user_id, references(:users), null: false
      add :text, :string, null: false
      add :timestamp, :utc_datetime, null: false

      timestamps([type: :utc_datetime])
    end
  end
end
