defmodule Core.Handler.CommandTest do
  use ExUnit.Case

  alias Ecto.Adapters.SQL.Sandbox
  alias Plug.Conn

  alias Core.Handler.Command
  alias Core.Helpers
  alias Storage.Helpers, as: StorageHelpers
  alias Storage.User
  alias Strings, as: S

  @ben Application.get_env(:storage, :ben_phone)

  setup do
    :ok = Sandbox.checkout(Storage)
    Sandbox.mode(Storage, {:shared, self()})

    bypass = Bypass.open(port: 9002)
    {:ok, bypass: bypass}
  end

  test "it inserts the user when a valid :add command is received", %{bypass: bypass} do
    StorageHelpers.insert_sms_relay(%{ip: "localhost"})
    message = Helpers.build_message(%{
      sender: @ben,
      text: "#{S.add_command()} Test User 5555555555"})

    Bypass.expect bypass, &(Conn.resp(&1, 200, ""))

    Command.handle(message)

    user = List.first(Storage.all(User))
    assert user.name == "Test User"
    assert user.phone == "5555555555"
  end

  test "it notifies the user when an :add command is successful", %{bypass: bypass} do
    StorageHelpers.insert_sms_relay(%{ip: "localhost"})
    message = Helpers.build_message(%{
      sender: @ben,
      text: "#{S.add_command()} Test User 5555555555"})

    Bypass.expect bypass, fn conn ->
      conn = Helpers.parse_body_params(conn)
      assert conn.params["recipient"] == @ben
      assert conn.params["text"] == S.user_added("Test User")
      Conn.resp(conn, 200, "")
    end

    Command.handle(message)
  end

  test "it notifies the user when an :add command fails", %{bypass: bypass} do
    StorageHelpers.insert_sms_relay(%{ip: "localhost"})
    message = Helpers.build_message(%{
      sender: @ben,
      text: "#{S.add_command()} Test User 5555555"})

    Bypass.expect bypass, fn conn ->
      conn = Helpers.parse_body_params(conn)
      assert conn.params["recipient"] == @ben
      assert conn.params["text"] == S.insert_failed()
      Conn.resp(conn, 200, "")
    end

    Command.handle(message)

    assert length(Storage.all(User)) == 0
  end

  test "it notifies the user when a command is invalid", %{bypass: bypass} do
    StorageHelpers.insert_sms_relay(%{ip: "localhost"})
    message = Helpers.build_message(%{
      sender: @ben,
      text: ":unknown Test User 5555555555"})

    Bypass.expect bypass, fn conn ->
      conn = Helpers.parse_body_params(conn)
      assert conn.params["recipient"] == @ben
      assert conn.params["text"] == S.invalid_command()
      Conn.resp(conn, 200, "")
    end

    Command.handle(message)

    assert length(Storage.all(User)) == 0
  end
end
