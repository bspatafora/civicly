defmodule Iteration.NotifierTest do
  use ExUnit.Case

  alias Ecto.Adapters.SQL.Sandbox
  alias Plug.Conn
  alias Plug.Parsers

  alias Iteration.Notifier
  alias Storage.{Conversation, Helpers}
  alias Strings, as: S

  defmodule MessageSpy do
    def new do
      Agent.start_link(fn -> [] end)
    end

    def record(agent, recipient, text) do
      Agent.update(agent, &([%{recipient: recipient, text: text} | &1]))
    end

    def get(agent) do
      Agent.get(agent, &(&1))
    end
  end

  def parse_body_params(conn) do
    opts = Parsers.init([parsers: [:json], json_decoder: Poison])
    Parsers.call(conn, opts)
  end

  setup do
    :ok = Sandbox.checkout(Storage)
    Sandbox.mode(Storage, {:shared, self()})

    bypass = Bypass.open(port: 9002)
    {:ok, bypass: bypass}
  end

  test "notify/0 sends each user dialog reminders and a notification that a new iteration has started", %{bypass: bypass} do
    user1 = Helpers.insert_user(%{name: "User 1"})
    user2 = Helpers.insert_user(%{name: "User 2"})
    user3 = Helpers.insert_user(%{name: "User 3"})
    sms_relay = Helpers.insert_sms_relay(%{ip: "localhost"})
    old_conversation_params =
      %{iteration: 1,
        sms_relay: sms_relay,
        users: [user1.id, user2.id, user3.id]}
    Helpers.insert_conversation(old_conversation_params)
    current_conversation_params =
      %{iteration: 2,
        sms_relay: sms_relay,
        users: [user1.id, user2.id, user3.id]}
    Helpers.insert_conversation(current_conversation_params)

    {:ok, messages} = MessageSpy.new()
    Bypass.expect bypass, fn conn ->
      conn = parse_body_params(conn)
      MessageSpy.record(messages, conn.params["recipient"], conn.params["text"])
      Conn.resp(conn, 200, "")
    end

    Notifier.notify("Test question?", "1")

    messages = MessageSpy.get(messages)
    assert length(messages) == 6

    assert_reminders = fn(user) ->
      message = %{recipient: user.phone, text: S.reminders()}
      assert Enum.member?(messages, message)
    end
    [user1, user2, user3] |> Enum.each(assert_reminders)

    user1_iteration_start =
      %{recipient: user1.phone,
        text: S.iteration_start(["User 2", "User 3"], "Test question?", "1")}
    user2_iteration_start =
      %{recipient: user2.phone,
        text: S.iteration_start(["User 1", "User 3"], "Test question?", "1")}
    user3_iteration_start =
      %{recipient: user3.phone,
        text: S.iteration_start(["User 1", "User 2"], "Test question?", "1")}

    [user1_iteration_start, user2_iteration_start, user3_iteration_start]
      |> Enum.each(&(assert Enum.member?(messages, &1)))
  end

  test "notify/0 notifies every user", %{bypass: bypass} do
    user1 = Helpers.insert_user(%{name: "User 1"})
    user2 = Helpers.insert_user(%{name: "User 2"})
    user3 = Helpers.insert_user(%{name: "User 3"})
    user4 = Helpers.insert_user(%{name: "User 4"})
    sms_relay = Helpers.insert_sms_relay(%{ip: "localhost"})
    params1 =
      %{iteration: 1,
        sms_relay: sms_relay,
        users: [user1.id, user2.id]}
    Helpers.insert_conversation(params1)
    params2 =
      %{iteration: 1,
        sms_relay: sms_relay,
        users: [user3.id, user4.id]}
    Helpers.insert_conversation(params2)

    {:ok, messages} = MessageSpy.new()
    Bypass.expect bypass, fn conn ->
      conn = parse_body_params(conn)
      MessageSpy.record(messages, conn.params["recipient"], conn.params["text"])
      Conn.resp(conn, 200, "")
    end

    Notifier.notify("Test question?", "1")

    messages = MessageSpy.get(messages)
    assert_reminders = fn(user) ->
      message = %{recipient: user.phone, text: S.reminders()}
      assert Enum.member?(messages, message)
    end
    [user1, user2, user3, user4] |> Enum.each(assert_reminders)
  end

  test "notify/0 sets each conversation's status to active", %{bypass: bypass} do
    sms_relay = Helpers.insert_sms_relay(%{ip: "localhost"})
    params1 =
      %{active: false,
        iteration: 1,
        sms_relay: sms_relay,
        users: [Helpers.insert_user().id, Helpers.insert_user().id]}
    conversation1 = Helpers.insert_conversation(params1)
    params2 =
      %{active: false,
        iteration: 1,
        sms_relay: sms_relay,
        users: [Helpers.insert_user().id, Helpers.insert_user().id]}
    conversation2 = Helpers.insert_conversation(params2)

    Bypass.expect bypass, &(Conn.resp(&1, 200, ""))

    Notifier.notify("Test question?", "1")

    [conversation1, conversation2]
      |> Enum.each(&(assert Storage.get(Conversation, &1.id).active? == true))
  end
end
