defmodule Storage.Migrations.AddActiveToConversations do
  use Ecto.Migration

  def change do
    alter table(:conversations) do
      add :active?, :boolean, default: false, null: false
    end
  end
end
