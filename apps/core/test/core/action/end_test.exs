defmodule Core.Action.EndTest do
  use ExUnit.Case

  alias Ecto.Adapters.SQL.Sandbox
  alias Plug.Conn

  alias Core.Action.End
  alias Core.Helpers
  alias Core.Helpers.MessageSpy
  alias Storage.Conversation
  alias Storage.Helpers, as: StorageHelpers
  alias Strings, as: S

  setup do
    :ok = Sandbox.checkout(Storage)
    Sandbox.mode(Storage, {:shared, self()})

    bypass = Bypass.open(port: 9002)
    {:ok, bypass: bypass}
  end

  test "execute/1 inactivates all conversations", %{bypass: bypass} do
    sms_relay = StorageHelpers.insert_sms_relay()
    conversation1 = StorageHelpers.insert_conversation(
      %{active?: true,
        iteration: 1,
        sms_relay_id: sms_relay.id})
    conversation2 = StorageHelpers.insert_conversation(
      %{active?: true,
        iteration: 2,
        sms_relay_id: sms_relay.id})

    Bypass.expect bypass, &(Conn.resp(&1, 200, ""))

    End.execute()

    [conversation1, conversation2]
      |> Enum.map(&(Storage.get(Conversation, &1.id)))
      |> Enum.each(&(assert &1.active? == false))
  end

  test "execute/1 notifies all users in active conversations that the iteration has ended", %{bypass: bypass} do
    sms_relay = StorageHelpers.insert_sms_relay()
    user1 = StorageHelpers.insert_user()
    user2 = StorageHelpers.insert_user()
    inactive = StorageHelpers.insert_user()
    StorageHelpers.insert_conversation(
      %{active?: true,
        iteration: 1,
        sms_relay_id: sms_relay.id,
        users: [user1.id, user2.id]})

    {:ok, messages} = MessageSpy.new()
    Bypass.expect bypass, fn conn ->
      conn = Helpers.parse_body_params(conn)
      MessageSpy.record(messages, conn.params["recipient"], conn.params["text"])
      Conn.resp(conn, 200, "")
    end

    End.execute()

    messages = MessageSpy.get(messages)
    assert length(messages) == 2
    text = S.iteration_end(-1)
    assert Enum.member?(messages, %{recipient: user1.phone, text: text})
    assert Enum.member?(messages, %{recipient: user2.phone, text: text})
    assert !Enum.member?(messages, %{recipient: inactive.phone, text: text})
  end
end
