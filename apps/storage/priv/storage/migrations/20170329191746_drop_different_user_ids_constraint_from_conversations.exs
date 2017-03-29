defmodule Storage.Migrations.DropDifferentUserIdsConstraintFromConversations do
  use Ecto.Migration

  def change do
    drop constraint(:conversations, :different_user_ids)
  end
end
