defmodule Core.RouterTest do
  use ExUnit.Case

  alias Ecto.Adapters.SQL.Sandbox
  alias Plug.Conn

  alias Core.{Helpers, Router}
  alias Storage.Helpers, as: StorageHelpers
  alias Storage.{Message, User}
  alias Strings, as: S
  alias Strings.Tutorial, as: T

  @ben Application.get_env(:storage, :ben_phone)

  setup do
    :ok = Sandbox.checkout(Storage)
    Sandbox.mode(Storage, {:shared, self()})

    bypass = Bypass.open(port: 9002)
    {:ok, bypass: bypass}
  end

  test "handle/1 routes an admin command", %{bypass: bypass} do
    StorageHelpers.insert_sms_relay()
    message = Helpers.build_message(
      %{sender: @ben,
        text: "#{S.add_command()} Test User 5555555555"})

    Bypass.expect bypass, &(Conn.resp(&1, 200, ""))

    Router.handle(message)

    assert length(Storage.all(User)) == 1
  end

  test "handle/1 routes a STOP request", %{bypass: bypass} do
    sms_relay = StorageHelpers.insert_sms_relay()
    user = StorageHelpers.insert_user()
    partner = StorageHelpers.insert_user()
    StorageHelpers.insert_conversation(
      %{active?: true,
        sms_relay_id: sms_relay.id,
        users: [user.id, partner.id]})
    message = Helpers.build_message(
      %{sender: user.phone,
        text: S.stop_request()})

    Bypass.expect bypass, &(Conn.resp(&1, 200, ""))

    Router.handle(message)

    assert Storage.get(User, user.id) == nil
  end

  test "handle/1 routes a STOP request regardless of capitalization or leading/trailing spaces", %{bypass: bypass} do
    sms_relay = StorageHelpers.insert_sms_relay()
    user = StorageHelpers.insert_user()
    partner = StorageHelpers.insert_user()
    StorageHelpers.insert_conversation(
      %{active?: true,
        sms_relay_id: sms_relay.id,
        users: [user.id, partner.id]})
    message = Helpers.build_message(
      %{sender: user.phone,
        text: " Stop "})

    Bypass.expect bypass, &(Conn.resp(&1, 200, ""))

    Router.handle(message)

    assert Storage.get(User, user.id) == nil
  end

  test "handle/1 routes a HELP request", %{bypass: bypass} do
    StorageHelpers.insert_sms_relay()
    phone = "5555555555"
    message = Helpers.build_message(
      %{sender: phone,
        text: S.help_request()})

    Bypass.expect bypass, fn conn ->
      conn = Helpers.parse_body_params(conn)
      assert conn.params["recipient"] == phone
      assert conn.params["text"] == S.help()
      Conn.resp(conn, 200, "")
    end

    Router.handle(message)
  end

  test "handle/1 routes a HELP request regardless of capitalization or leading/trailing spaces", %{bypass: bypass} do
    StorageHelpers.insert_sms_relay()
    phone = "5555555555"
    message = Helpers.build_message(
      %{sender: phone,
        text: " Help "})

    Bypass.expect bypass, fn conn ->
      conn = Helpers.parse_body_params(conn)
      assert conn.params["recipient"] == phone
      assert conn.params["text"] == S.help()
      Conn.resp(conn, 200, "")
    end

    Router.handle(message)
  end

  test "handle/1 routes a tutorial message", %{bypass: bypass} do
    StorageHelpers.insert_sms_relay()
    user = StorageHelpers.insert_user(%{tutorial_step: 1})
    message = Helpers.build_message(
      %{sender: user.phone,
        text: T.step_1_key})

    Bypass.expect bypass, &(Conn.resp(&1, 200, ""))

    Router.handle(message)

    user = Storage.get(User, user.id)
    assert user.tutorial_step == 2
  end

  test "handle/1 routes a missive", %{bypass: bypass} do
    sms_relay = StorageHelpers.insert_sms_relay()
    user = StorageHelpers.insert_user()
    StorageHelpers.insert_conversation(
      %{active?: true,
        sms_relay_id: sms_relay.id,
        users: [user.id, StorageHelpers.insert_user().id]})
    text = "Test message"
    message = Helpers.build_message(
      %{sender: user.phone,
        text: text})

    Bypass.expect bypass, &(Conn.resp(&1, 200, ""))

    Router.handle(message)

    assert length(Storage.all(Message)) == 1
  end

  test "handle/1 does not throw an error when the sender is not in the database" do
    StorageHelpers.insert_sms_relay()
    phone = "5555555555"
    message = Helpers.build_message(
      %{sender: phone,
        text: "Test message"})

    Router.handle(message)
  end
end
