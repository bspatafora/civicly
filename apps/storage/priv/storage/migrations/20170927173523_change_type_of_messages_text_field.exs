defmodule Storage.Migrations.ChangeTypeOfMessagesTextField do
  use Ecto.Migration

  def change do
    alter table(:messages) do
      modify :text, :text
    end
  end
end
