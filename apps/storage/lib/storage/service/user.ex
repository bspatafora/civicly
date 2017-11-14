defmodule Storage.Service.User do
  @moduledoc false

  import Ecto.Query

  alias Storage.User

  def by_phone(phone) do
    query = from User, where: [phone: ^phone]

    Storage.one(query)
  end

  def all do
    Storage.all(User)
  end

  def all_enabled do
    query = from User, where: [tutorial_step: 0]

    Storage.all(query)
  end

  def name(phone) do
    by_phone(phone).name
  end

  def insert(name, phone) do
    params =
      %{name: name,
        phone: phone,
        tutorial_step: 1}
    changeset = User.changeset(%User{}, params)

    Storage.insert(changeset)
  end

  def delete(phone) do
    user = Storage.get_by!(User, phone: phone)
    Storage.delete!(user)
  end

  def exists?(phone) do
    case by_phone(phone) do
      nil -> false
      _ -> true
    end
  end

  def in_tutorial?(phone) do
    tutorial_step(phone) != 0
  end

  def tutorial_step(phone) do
    by_phone(phone).tutorial_step
  end

  def advance_tutorial(phone) do
    user = by_phone(phone)
    step = user.tutorial_step

    new_step = if step == 5, do: 0, else: step + 1

    user
      |> User.changeset(%{tutorial_step: new_step})
      |> Storage.update!
  end
end
