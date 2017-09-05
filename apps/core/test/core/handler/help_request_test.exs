defmodule Core.Handler.HelpRequestTest do
  use ExUnit.Case

  alias Ecto.Adapters.SQL.Sandbox
  alias Plug.Conn

  alias Core.Handler.HelpRequest
  alias Core.Helpers
  alias Storage.Helpers, as: StorageHelpers
  alias Strings, as: S

  setup do
    :ok = Sandbox.checkout(Storage)
    Sandbox.mode(Storage, {:shared, self()})

    bypass = Bypass.open(port: 9002)
    {:ok, bypass: bypass}
  end

  test "handle/1 responds to the sender with the help text", %{bypass: bypass} do
    StorageHelpers.insert_sms_relay()
    phone = "5555555555"
    message = Helpers.build_message(
      %{sender: phone,
        text: "HELP"})

    Bypass.expect bypass, fn conn ->
      conn = Helpers.parse_body_params(conn)
      assert conn.params["recipient"] == phone
      assert conn.params["text"] == S.help()
      Conn.resp(conn, 200, "")
    end

    HelpRequest.handle(message)
  end
end
