defmodule Core.Action.PromptTest do
  use ExUnit.Case

  alias Ecto.Adapters.SQL.Sandbox
  alias Plug.Conn

  alias Core.Action.Prompt
  alias Core.Helpers
  alias Core.Helpers.MessageSpy
  alias Storage.Helpers, as: StorageHelpers

  setup do
    :ok = Sandbox.checkout(Storage)
    Sandbox.mode(Storage, {:shared, self()})

    bypass = Bypass.open(port: 9002)
    {:ok, bypass: bypass}
  end

  test "send/1 sends a randomly selected prompt to the user and their partner", %{bypass: bypass} do
    user = StorageHelpers.insert_user()
    partner = StorageHelpers.insert_user()
    StorageHelpers.insert_conversation(
      %{active?: true,
        users: [user.id, partner.id]})
    message = Helpers.build_message(
      %{sender: user.phone,
        text: "Prompt"})

    {:ok, messages} = MessageSpy.new()
    Bypass.expect bypass, fn conn ->
      conn = Helpers.parse_body_params(conn)
      MessageSpy.record(messages, conn.params["recipient"], conn.params["text"])
      Conn.resp(conn, 200, "")
    end

    Prompt.send(message)

    messages = MessageSpy.get(messages)
    assert length(messages) == 3

    prompt = messages
      |> Enum.reject(&(&1.text == "Prompt"))
      |> Enum.take(1)
      |> Enum.map(&(&1.text))
      |> List.first()
    assert String.ends_with?(prompt, "?")
    assert Enum.member?(messages, %{recipient: user.phone, text: prompt})
    assert Enum.member?(messages, %{recipient: partner.phone, text: prompt})
  end

  test "send/1 sends the text of the user's Prompt command to their partner", %{bypass: bypass} do
    user = StorageHelpers.insert_user()
    partner = StorageHelpers.insert_user()
    StorageHelpers.insert_conversation(
      %{active?: true,
        users: [user.id, partner.id]})
    command_text = "Prompt"
    message = Helpers.build_message(
      %{sender: user.phone,
        text: command_text})

    {:ok, messages} = MessageSpy.new()
    Bypass.expect bypass, fn conn ->
      conn = Helpers.parse_body_params(conn)
      MessageSpy.record(messages, conn.params["recipient"], conn.params["text"])
      Conn.resp(conn, 200, "")
    end

    Prompt.send(message)

    messages = MessageSpy.get(messages)
    assert length(messages) == 3
    assert Enum.member?(messages, %{recipient: partner.phone, text: command_text})
  end
end
