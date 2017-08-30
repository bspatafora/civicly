defmodule Core.Handler.CommandTest do
  use ExUnit.Case

  alias Ecto.Adapters.SQL.Sandbox
  alias Plug.Conn

  alias Core.Handler.Command
  alias Core.Helpers
  alias Core.Helpers.MessageSpy
  alias Storage.Helpers, as: StorageHelpers
  alias Storage.{Conversation, User}
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

  test "it notifies the admin when an :add command is successful", %{bypass: bypass} do
    StorageHelpers.insert_sms_relay(%{ip: "localhost"})
    message = Helpers.build_message(%{
      sender: @ben,
      text: "#{S.add_command()} Test User 5555555555"})

    {:ok, messages} = MessageSpy.new()
    Bypass.expect bypass, fn conn ->
      conn = Helpers.parse_body_params(conn)
      MessageSpy.record(messages, conn.params["recipient"], conn.params["text"])
      Conn.resp(conn, 200, "")
    end

    Command.handle(message)

    messages = MessageSpy.get(messages)
    assert length(messages) == 2
    user_added_message = %{recipient: @ben, text: S.user_added("Test User")}
    assert Enum.member?(messages, user_added_message)
  end

  test "it welcomes the user when an :add command is successful", %{bypass: bypass} do
    StorageHelpers.insert_sms_relay(%{ip: "localhost"})
    new_user_phone = "5555555555"
    message = Helpers.build_message(%{
      sender: @ben,
      text: "#{S.add_command()} Test User #{new_user_phone}"})

    {:ok, messages} = MessageSpy.new()
    Bypass.expect bypass, fn conn ->
      conn = Helpers.parse_body_params(conn)
      MessageSpy.record(messages, conn.params["recipient"], conn.params["text"])
      Conn.resp(conn, 200, "")
    end

    Command.handle(message)

    messages = MessageSpy.get(messages)
    assert length(messages) == 2
    welcome_message = %{recipient: new_user_phone, text: S.welcome()}
    assert Enum.member?(messages, welcome_message)
  end

  test "it notifies the admin when an :add command fails", %{bypass: bypass} do
    StorageHelpers.insert_sms_relay(%{ip: "localhost"})
    name = "Test User"
    phone = "5555555555"
    StorageHelpers.insert_user(%{name: name, phone: phone})
    message = Helpers.build_message(%{
      sender: @ben,
      text: "#{S.add_command()} #{name} #{phone}"})

    Bypass.expect bypass, fn conn ->
      conn = Helpers.parse_body_params(conn)
      assert conn.params["recipient"] == @ben
      assert conn.params["text"] == S.insert_failed()
      Conn.resp(conn, 200, "")
    end

    Command.handle(message)
  end

  test "it notifies the admin when a command is invalid", %{bypass: bypass} do
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

  test "it sends the text to the specified phone when a valid :msg command is received", %{bypass: bypass} do
    StorageHelpers.insert_sms_relay(%{ip: "localhost"})
    phone = "5555555555"
    text = "Test message"
    message = Helpers.build_message(%{
      sender: @ben,
      text: "#{S.msg_command()} #{phone} #{text}"})

    Bypass.expect bypass, fn conn ->
      conn = Helpers.parse_body_params(conn)
      assert conn.params["recipient"] == phone
      assert conn.params["text"] == text
      Conn.resp(conn, 200, "")
    end

    Command.handle(message)
  end

  test "it starts a new iteration when a valid :new command is received", %{bypass: bypass} do
    StorageHelpers.insert_sms_relay(%{ip: "localhost"})
    StorageHelpers.insert_user(%{phone: @ben})
    StorageHelpers.insert_user(%{name: "Test User"}).id
    message = Helpers.build_message(%{
      sender: @ben,
      text: "#{S.new_command()} 1 Test question?"})

    {:ok, messages} = MessageSpy.new()
    Bypass.expect bypass, fn conn ->
      conn = Helpers.parse_body_params(conn)
      MessageSpy.record(messages, conn.params["recipient"], conn.params["text"])
      Conn.resp(conn, 200, "")
    end

    Command.handle(message)

    assert length(Storage.all(Conversation)) == 1
    iteration_start = S.iteration_start(["Test User"], "Test question?", "1")
    messages = MessageSpy.get(messages)
    assert Enum.member?(messages, %{recipient: @ben, text: iteration_start})
  end
end
