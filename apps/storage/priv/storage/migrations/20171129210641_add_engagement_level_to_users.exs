defmodule Storage.Migrations.AddEngagementLevelToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :engagement_level, :integer, default: -1, null: false
    end
  end
end
