defmodule Storage.Migrations.AddActivatedAtToConversations do
  use Ecto.Migration

  def change do
    alter table(:conversations) do
      add :activated_at, :utc_datetime
    end
  end
end
