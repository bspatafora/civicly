defmodule Storage.Migrations.CreateRecentlyReceivedMessages do
  use Ecto.Migration

  def change do
    create table(:recently_received_messages) do
      add :sender, :string, size: 10, null: false
      add :text, :text, null: false
      add :timestamp, :utc_datetime, null: false

      timestamps([type: :utc_datetime])
    end
  end
end
