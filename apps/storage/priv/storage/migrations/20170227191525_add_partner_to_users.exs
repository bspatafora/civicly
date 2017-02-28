defmodule Storage.Migrations.AddPartnerToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :partner_id, references(:users, [on_delete: :nilify_all])
    end

    create unique_index(:users, [:partner_id])
  end
end
