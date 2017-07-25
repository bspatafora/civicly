defmodule Core.Handler.StopRequestTest do
  use ExUnit.Case

  alias Ecto.Adapters.SQL.Sandbox
  alias Plug.Conn

  alias Core.Handler.StopRequest
  alias Core.Helpers
  alias Core.Helpers.MessageSpy
  alias Storage.Helpers, as: StorageHelpers
  alias Storage.User

  setup do
    :ok = Sandbox.checkout(Storage)
    Sandbox.mode(Storage, {:shared, self()})

    bypass = Bypass.open(port: 9002)
    {:ok, bypass: bypass}
  end

  test "it deletes the user who sent the STOP request", %{bypass: bypass} do
    user = StorageHelpers.insert_user()
    partner = StorageHelpers.insert_user()
    sms_relay = StorageHelpers.insert_sms_relay(%{ip: "localhost"})
    StorageHelpers.insert_conversation(%{
      sms_relay_id: sms_relay.id,
      users: [user.id, partner.id]})
    message = Helpers.build_message(%{
      sender: user.phone,
      text: "STOP"})

    Bypass.expect bypass, &(Conn.resp(&1, 200, ""))

    StopRequest.handle(message)

    assert Storage.get(User, user.id) == nil
  end

  test "it notifies the user and their partners", %{bypass: bypass} do
    user = StorageHelpers.insert_user()
    partner1 = StorageHelpers.insert_user()
    partner2 = StorageHelpers.insert_user()
    sms_relay = StorageHelpers.insert_sms_relay(%{ip: "localhost"})
    StorageHelpers.insert_conversation(%{
      sms_relay_id: sms_relay.id,
      users: [user.id, partner1.id, partner2.id]})
    message = Helpers.build_message(%{
      sender: user.phone,
      text: "STOP"})

    {:ok, messages} = MessageSpy.new()
    Bypass.expect bypass, fn conn ->
      conn = Helpers.parse_body_params(conn)
      MessageSpy.record(messages, conn.params["recipient"], conn.params["text"])
      Conn.resp(conn, 200, "")
    end

    StopRequest.handle(message)

    messages = MessageSpy.get(messages)
    assert length(messages) == 3
    assert Enum.member?(messages, %{recipient: user.phone, text: "You have been deleted"})
    assert Enum.member?(messages, %{recipient: partner1.phone, text: "#{user.name} has quit"})
    assert Enum.member?(messages, %{recipient: partner2.phone, text: "#{user.name} has quit"})
  end
end