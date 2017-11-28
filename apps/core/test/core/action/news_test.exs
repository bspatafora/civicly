defmodule Core.Action.NewsTest do
  use ExUnit.Case

  alias Ecto.Adapters.SQL.Sandbox
  alias Plug.Conn

  alias Core.Action.News
  alias Core.Helpers
  alias Core.Helpers.MessageSpy
  alias Storage.Helpers, as: StorageHelpers
  alias Strings, as: S

  setup do
    :ok = Sandbox.checkout(Storage)
    Sandbox.mode(Storage, {:shared, self()})

    bypass = Bypass.open(port: 9002)
    {:ok, bypass: bypass}
  end

  test "check/1 sends the AP top story to the command issuer", %{bypass: bypass} do
    StorageHelpers.insert_sms_relay()
    sender = "5555555555"
    message = Helpers.build_message(
      %{sender: sender,
        text: S.news_check_command()})

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

    News.check(message)

    messages = MessageSpy.get(messages)
    assert length(messages) == 1
    story = "[civicly] (Reuters) After victory in Raqqa over IS, Kurds face tricky peace https://goo.gl/fbsS"
    assert Enum.member?(messages, %{recipient: sender, text: story})
  end

  test "send/1 sends out the AP top story to all users in active conversations", %{bypass: bypass} do
    sms_relay = StorageHelpers.insert_sms_relay()
    user1 = StorageHelpers.insert_user()
    user2 = StorageHelpers.insert_user()
    inactive = StorageHelpers.insert_user()
    StorageHelpers.insert_conversation(
      %{active?: true,
        iteration: 1,
        sms_relay_id: sms_relay.id,
        users: [user1.id, user2.id]})
    message = Helpers.build_message(
      %{sender: "5555555555",
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

    News.send(message)

    messages = MessageSpy.get(messages)
    story = "[civicly] (Reuters) After victory in Raqqa over IS, Kurds face tricky peace https://goo.gl/fbsS"
    assert Enum.member?(messages, %{recipient: user1.phone, text: story})
    assert Enum.member?(messages, %{recipient: user2.phone, text: story})
    assert !Enum.member?(messages, %{recipient: inactive.phone, text: story})
  end
end
