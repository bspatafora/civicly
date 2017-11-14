defmodule Storage.Service.SMSRelay do
  @moduledoc false

  import Ecto.Changeset
  import Ecto.Query

  alias Storage.SMSRelay

  def update_ip(ip) do
    first() |> change(ip: ip) |> Storage.update!
  end

  def get do
    first()
  end

  defp first do
    SMSRelay |> first |> Storage.one
  end
end
