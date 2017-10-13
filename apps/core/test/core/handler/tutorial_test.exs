defmodule Core.Handler.TutorialTest do
  use ExUnit.Case

  alias Ecto.Adapters.SQL.Sandbox
  alias Plug.Conn

  alias Core.Handler.Tutorial
  alias Core.Helpers
  alias Core.Helpers.MessageSpy
  alias Storage.Helpers, as: StorageHelpers
  alias Strings.Tutorial, as: S
  alias Storage.User

  setup do
    :ok = Sandbox.checkout(Storage)
    Sandbox.mode(Storage, {:shared, self()})

    bypass = Bypass.open(port: 9002)
    {:ok, bypass: bypass}
  end

  test "handle/1 advances the user from step 1 to step 2 when they send the key (regardless of case/spacing/period use)", %{bypass: bypass} do
    StorageHelpers.insert_sms_relay()
    user = StorageHelpers.insert_user(%{tutorial_step: 1})
    message = Helpers.build_message(
      %{sender: user.phone,
        text: "#{String.upcase(S.step_1_key)}. "})

    {:ok, messages} = MessageSpy.new()
    Bypass.expect bypass, fn conn ->
      conn = Helpers.parse_body_params(conn)
      MessageSpy.record(messages, conn.params["recipient"], conn.params["text"])
      Conn.resp(conn, 200, "")
    end

    Tutorial.handle(message)

    user = Storage.get(User, user.id)
    assert user.tutorial_step == 2

    messages = MessageSpy.get(messages)
    assert length(messages) == 2
    texts = messages |> Enum.map(&(&1.text))
    assert Enum.member?(texts, S.step_2_part_1())
    assert Enum.member?(texts, S.step_2_part_2())
  end

  test "handle/1 sends an error message and does not advance a user from step 1 when they send something other than the key", %{bypass: bypass} do
    StorageHelpers.insert_sms_relay()
    user = StorageHelpers.insert_user(%{tutorial_step: 1})
    message = Helpers.build_message(
      %{sender: user.phone,
        text: "Error"})

    {:ok, messages} = MessageSpy.new()
    Bypass.expect bypass, fn conn ->
      conn = Helpers.parse_body_params(conn)
      MessageSpy.record(messages, conn.params["recipient"], conn.params["text"])
      Conn.resp(conn, 200, "")
    end

    Tutorial.handle(message)

    user = Storage.get(User, user.id)
    assert user.tutorial_step == 1

    messages = MessageSpy.get(messages)
    assert length(messages) == 1
    assert List.first(messages).text == S.step_1_error()
  end

  test "handle/1 advances the user from step 2 to step 3 when they send the key (regardless of case/spacing/period use)", %{bypass: bypass} do
    StorageHelpers.insert_sms_relay()
    user = StorageHelpers.insert_user(%{tutorial_step: 2})
    message = Helpers.build_message(
      %{sender: user.phone,
        text: "#{String.upcase(S.step_2_key)}. "})

    {:ok, messages} = MessageSpy.new()
    Bypass.expect bypass, fn conn ->
      conn = Helpers.parse_body_params(conn)
      MessageSpy.record(messages, conn.params["recipient"], conn.params["text"])
      Conn.resp(conn, 200, "")
    end

    Tutorial.handle(message)

    user = Storage.get(User, user.id)
    assert user.tutorial_step == 3

    messages = MessageSpy.get(messages)
    assert length(messages) == 2
    texts = messages |> Enum.map(&(&1.text))
    assert Enum.member?(texts, S.step_3_part_1())
    assert Enum.member?(texts, S.step_3_part_2(user.name))
  end

  test "handle/1 sends an error message and does not advance a user from step 2 when they send something other than the key", %{bypass: bypass} do
    StorageHelpers.insert_sms_relay()
    user = StorageHelpers.insert_user(%{tutorial_step: 2})
    message = Helpers.build_message(
      %{sender: user.phone,
        text: "Error"})

    {:ok, messages} = MessageSpy.new()
    Bypass.expect bypass, fn conn ->
      conn = Helpers.parse_body_params(conn)
      MessageSpy.record(messages, conn.params["recipient"], conn.params["text"])
      Conn.resp(conn, 200, "")
    end

    Tutorial.handle(message)

    user = Storage.get(User, user.id)
    assert user.tutorial_step == 2

    messages = MessageSpy.get(messages)
    assert length(messages) == 1
    assert List.first(messages).text == S.step_2_error()
  end

  test "handle/1 advances the user from step 3 to step 4 when they send anything", %{bypass: bypass} do
    StorageHelpers.insert_sms_relay()
    user = StorageHelpers.insert_user(%{tutorial_step: 3})
    message = Helpers.build_message(
      %{sender: user.phone,
        text: "My favorite color is purple"})

    {:ok, messages} = MessageSpy.new()
    Bypass.expect bypass, fn conn ->
      conn = Helpers.parse_body_params(conn)
      MessageSpy.record(messages, conn.params["recipient"], conn.params["text"])
      Conn.resp(conn, 200, "")
    end

    Tutorial.handle(message)

    user = Storage.get(User, user.id)
    assert user.tutorial_step == 4

    messages = MessageSpy.get(messages)
    assert length(messages) == 2
    texts = messages |> Enum.map(&(&1.text))
    assert Enum.member?(texts, S.step_4_part_1())
    assert Enum.member?(texts, S.step_4_part_2())
  end

  test "handle/1 advances the user from step 4 to step 5 when they send the key (regardless of case/spacing/period use)", %{bypass: bypass} do
    StorageHelpers.insert_sms_relay()
    user = StorageHelpers.insert_user(%{tutorial_step: 4})
    message = Helpers.build_message(
      %{sender: user.phone,
        text: "#{String.upcase(S.step_4_key)}. "})

    {:ok, messages} = MessageSpy.new()
    Bypass.expect bypass, fn conn ->
      conn = Helpers.parse_body_params(conn)
      MessageSpy.record(messages, conn.params["recipient"], conn.params["text"])
      Conn.resp(conn, 200, "")
    end

    Tutorial.handle(message)

    user = Storage.get(User, user.id)
    assert user.tutorial_step == 5

    messages = MessageSpy.get(messages)
    assert length(messages) == 1
    assert List.first(messages).text == S.step_5()
  end

  test "handle/1 sends an error message and does not advance a user from step 4 when they send something other than the key", %{bypass: bypass} do
    StorageHelpers.insert_sms_relay()
    user = StorageHelpers.insert_user(%{tutorial_step: 4})
    message = Helpers.build_message(
      %{sender: user.phone,
        text: "Error"})

    {:ok, messages} = MessageSpy.new()
    Bypass.expect bypass, fn conn ->
      conn = Helpers.parse_body_params(conn)
      MessageSpy.record(messages, conn.params["recipient"], conn.params["text"])
      Conn.resp(conn, 200, "")
    end

    Tutorial.handle(message)

    user = Storage.get(User, user.id)
    assert user.tutorial_step == 4

    messages = MessageSpy.get(messages)
    assert length(messages) == 1
    assert List.first(messages).text == S.step_4_error()
  end

  test "handle/1 advances the user from step 5 to step 0 when they send the key (regardless of case/spacing/period use)", %{bypass: bypass} do
    StorageHelpers.insert_sms_relay()
    user = StorageHelpers.insert_user(%{tutorial_step: 5})
    message = Helpers.build_message(
      %{sender: user.phone,
        text: "#{String.upcase(S.step_5_key)}. "})

    {:ok, messages} = MessageSpy.new()
    Bypass.expect bypass, fn conn ->
      conn = Helpers.parse_body_params(conn)
      MessageSpy.record(messages, conn.params["recipient"], conn.params["text"])
      Conn.resp(conn, 200, "")
    end

    Tutorial.handle(message)

    user = Storage.get(User, user.id)
    assert user.tutorial_step == 0

    messages = MessageSpy.get(messages)
    assert length(messages) == 2
    texts = messages |> Enum.map(&(&1.text))
    assert Enum.member?(texts, S.complete_part_1())
    assert Enum.member?(texts, S.complete_part_2())
  end

  test "handle/1 sends an error message and does not advance a user from step 5 when they send something other than the key", %{bypass: bypass} do
    StorageHelpers.insert_sms_relay()
    user = StorageHelpers.insert_user(%{tutorial_step: 5})
    message = Helpers.build_message(
      %{sender: user.phone,
        text: "Error"})

    {:ok, messages} = MessageSpy.new()
    Bypass.expect bypass, fn conn ->
      conn = Helpers.parse_body_params(conn)
      MessageSpy.record(messages, conn.params["recipient"], conn.params["text"])
      Conn.resp(conn, 200, "")
    end

    Tutorial.handle(message)

    user = Storage.get(User, user.id)
    assert user.tutorial_step == 5

    messages = MessageSpy.get(messages)
    assert length(messages) == 1
    assert List.first(messages).text == S.step_5_error()
  end
end
