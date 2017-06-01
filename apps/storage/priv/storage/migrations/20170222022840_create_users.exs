defmodule Storage.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :name, :string, null: false, size: 100
      add :phone, :string, null: false, size: 10

      timestamps()
    end

    create unique_index(:users, [:phone])
  end
end
