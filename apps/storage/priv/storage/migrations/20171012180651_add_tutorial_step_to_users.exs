defmodule Storage.Migrations.AddTutorialStepToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :tutorial_step, :integer, default: 0, null: false
    end
  end
end
