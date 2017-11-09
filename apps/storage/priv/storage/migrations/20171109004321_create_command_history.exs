defmodule Storage.Migrations.CreateCommandHistory do
  use Ecto.Migration

  def change do
    create table(:command_history) do
      add :text, :text, null: false
      add :timestamp, :utc_datetime, null: false

      timestamps([type: :utc_datetime])
    end
  end
end
