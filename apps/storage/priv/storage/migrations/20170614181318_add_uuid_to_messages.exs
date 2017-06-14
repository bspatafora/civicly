defmodule Storage.Migrations.AddUUIDToMessages do
  use Ecto.Migration

  def change do
    alter table(:messages) do
      add :uuid, :uuid, null: false
    end
  end
end
