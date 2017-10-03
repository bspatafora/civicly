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

  test "handle/1 inserts a new user when it receives a valid :add command", %{bypass: bypass} do
    StorageHelpers.insert_sms_relay()
    message = Helpers.build_message(
      %{sender: @ben,
        text: "#{S.add_command()} Test User 5555555555"})

    Bypass.expect bypass, &(Conn.resp(&1, 200, ""))

    Command.handle(message)

    user = List.first(Storage.all(User))
    assert user.name == "Test User"
    assert user.phone == "5555555555"
  end

  test "handle/1 notifies the sender when an :add command succeeds", %{bypass: bypass} do
    StorageHelpers.insert_sms_relay()
    message = Helpers.build_message(
      %{sender: @ben,
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

  test "handle/1 welcomes the new user when an :add command succeeds", %{bypass: bypass} do
    StorageHelpers.insert_sms_relay()
    new_user_phone = "5555555555"
    message = Helpers.build_message(
      %{sender: @ben,
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

  test "handle/1 notifies the sender when an :add command fails", %{bypass: bypass} do
    StorageHelpers.insert_sms_relay()
    existing_user = StorageHelpers.insert_user(
      %{name: "Test User",
        phone: "5555555555"})
    message = Helpers.build_message(
      %{sender: @ben,
        text: "#{S.add_command()} #{existing_user.name} #{existing_user.phone}"})

    Bypass.expect bypass, fn conn ->
      conn = Helpers.parse_body_params(conn)
      assert conn.params["recipient"] == @ben
      assert conn.params["text"] == S.insert_failed()
      Conn.resp(conn, 200, "")
    end

    Command.handle(message)
  end

  test "handle/1 notifies the sender when a command is invalid", %{bypass: bypass} do
    StorageHelpers.insert_sms_relay()
    message = Helpers.build_message(
      %{sender: @ben,
        text: ":unknown_command"})

    Bypass.expect bypass, fn conn ->
      conn = Helpers.parse_body_params(conn)
      assert conn.params["recipient"] == @ben
      assert conn.params["text"] == S.invalid_command()
      Conn.resp(conn, 200, "")
    end

    Command.handle(message)
  end

  test "handle/1 forwards the message to the specified phone when it receives a valid :msg command", %{bypass: bypass} do
    StorageHelpers.insert_sms_relay()
    phone = "5555555555"
    text = "Test message"
    message = Helpers.build_message(
      %{sender: @ben,
        text: "#{S.msg_command()} #{phone} #{text}"})

    Bypass.expect bypass, fn conn ->
      conn = Helpers.parse_body_params(conn)
      assert conn.params["recipient"] == phone
      assert conn.params["text"] == S.prepend_civicly(text)
      Conn.resp(conn, 200, "")
    end

    Command.handle(message)
  end

  test "handle/1 starts a new iteration when it receives a valid :new command", %{bypass: bypass} do
    StorageHelpers.insert_sms_relay()
    StorageHelpers.insert_user(%{phone: @ben})
    StorageHelpers.insert_user(%{name: "Test User"})
    message = Helpers.build_message(
      %{sender: @ben,
        text: "#{S.new_command()} Test question?"})

    {:ok, messages} = MessageSpy.new()
    Bypass.expect bypass, fn conn ->
      conn = Helpers.parse_body_params(conn)
      MessageSpy.record(messages, conn.params["recipient"], conn.params["text"])
      Conn.resp(conn, 200, "")
    end

    Command.handle(message)

    assert length(Storage.all(Conversation)) == 1
    messages = MessageSpy.get(messages)
    assert length(messages) == 4
    start_message = S.iteration_start(["Test User"])
    assert Enum.member?(messages, %{recipient: @ben, text: start_message})
  end

  test "handle/1 notifies all users of a new iteration when it receives a valid :notify command", %{bypass: bypass} do
    sms_relay = StorageHelpers.insert_sms_relay()
    user = StorageHelpers.insert_user(%{phone: @ben})
    partner = StorageHelpers.insert_user(%{name: "Test User"})
    StorageHelpers.insert_conversation(
      %{active?: false,
        iteration: 1,
        sms_relay_id: sms_relay.id,
        users: [user.id, partner.id]})
    message = Helpers.build_message(
      %{sender: @ben,
        text: "#{S.notify_command()} Test question?"})

    {:ok, messages} = MessageSpy.new()
    Bypass.expect bypass, fn conn ->
      conn = Helpers.parse_body_params(conn)
      MessageSpy.record(messages, conn.params["recipient"], conn.params["text"])
      Conn.resp(conn, 200, "")
    end

    Command.handle(message)

    assert length(Storage.all(Conversation)) == 1
    messages = MessageSpy.get(messages)
    assert length(messages) == 4
    start_message = S.iteration_start(["Test User"])
    assert Enum.member?(messages, %{recipient: @ben, text: start_message})
  end

  test "handle/1 ends the iteration when it receives valid :end command", %{bypass: bypass} do
    sms_relay = StorageHelpers.insert_sms_relay()
    conversation1 = StorageHelpers.insert_conversation(
      %{active?: true,
        iteration: 1,
        sms_relay_id: sms_relay.id})
    conversation2 = StorageHelpers.insert_conversation(
      %{active?: true,
        iteration: 2,
        sms_relay_id: sms_relay.id})
    message = Helpers.build_message(
      %{sender: @ben,
        text: S.end_command()})

    Bypass.expect bypass, &(Conn.resp(&1, 200, ""))

    Command.handle(message)

    [conversation1, conversation2]
      |> Enum.map(&(Storage.get(Conversation, &1.id)))
      |> Enum.each(&(assert &1.active? == false))
  end

  test "handle/1 notifies every user that the iteration has ended when it receives a valid :end command", %{bypass: bypass} do
    sms_relay = StorageHelpers.insert_sms_relay()
    user1 = StorageHelpers.insert_user()
    user2 = StorageHelpers.insert_user()
    user3 = StorageHelpers.insert_user()
    user4 = StorageHelpers.insert_user()
    StorageHelpers.insert_conversation(
      %{active?: true,
        iteration: 1,
        sms_relay_id: sms_relay.id,
        users: [user1.id, user2.id]})
    StorageHelpers.insert_conversation(
      %{active?: true,
        iteration: 2,
        sms_relay_id: sms_relay.id,
        users: [user3.id, user4.id]})
    message = Helpers.build_message(
      %{sender: @ben,
        text: S.end_command()})

    {:ok, messages} = MessageSpy.new()
    Bypass.expect bypass, fn conn ->
      conn = Helpers.parse_body_params(conn)
      MessageSpy.record(messages, conn.params["recipient"], conn.params["text"])
      Conn.resp(conn, 200, "")
    end

    Command.handle(message)

    messages = MessageSpy.get(messages)
    assert_end_message = fn(user) ->
      end_message = %{recipient: user.phone, text: S.iteration_end()}
      assert Enum.member?(messages, end_message)
    end
    [user1, user2, user3, user4] |> Enum.each(assert_end_message)
  end

  test "handle/1 forwards the message to all phones when it receives an :all command", %{bypass: bypass} do
    StorageHelpers.insert_sms_relay()
    user1 = StorageHelpers.insert_user()
    user2 = StorageHelpers.insert_user()
    text = "Test message"
    message = Helpers.build_message(
      %{sender: @ben,
        text: "#{S.all_command()} #{text}"})

    {:ok, messages} = MessageSpy.new()
    Bypass.expect bypass, fn conn ->
      conn = Helpers.parse_body_params(conn)
      MessageSpy.record(messages, conn.params["recipient"], conn.params["text"])
      Conn.resp(conn, 200, "")
    end

    Command.handle(message)

    messages = MessageSpy.get(messages)
    assert length(messages) == 2
    text = S.prepend_civicly(text)
    assert Enum.member?(messages, %{recipient: user1.phone, text: text})
    assert Enum.member?(messages, %{recipient: user2.phone, text: text})
  end

  test "handle/1 sends out the AP top story when it receives a valid :news command", %{bypass: bypass} do
    StorageHelpers.insert_sms_relay()
    user1 = StorageHelpers.insert_user()
    user2 = StorageHelpers.insert_user()
    message = Helpers.build_message(
      %{sender: @ben,
        text: S.news_command()})

    Bypass.expect bypass, "GET", "/v1/articles", fn conn ->
      response_body = File.read!("test/core/api_client/news_api_response.txt")
      Conn.resp(conn, 200, response_body)
    end

    Bypass.expect bypass, "POST", "/urlshortener/v1/url", fn conn ->
      response_body = File.read!("test/core/api_client/googl_response.txt")
      Conn.resp(conn, 200, response_body)
    end

    {:ok, messages} = MessageSpy.new()
    Bypass.expect bypass, fn conn ->
      conn = Helpers.parse_body_params(conn)
      MessageSpy.record(messages, conn.params["recipient"], conn.params["text"])
      Conn.resp(conn, 200, "")
    end

    Command.handle(message)

    messages = MessageSpy.get(messages)
    news_text = "[civicly] (AP) Sniper in high-rise hotel kills at least 58 in Las Vegas goo.gl/fbsS"
    assert_news_message = fn(user) ->
      news_message = %{recipient: user.phone, text: news_text}
      assert Enum.member?(messages, news_message)
    end
    [user1, user2] |> Enum.each(assert_news_message)
  end
end
