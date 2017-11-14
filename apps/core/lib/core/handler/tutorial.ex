defmodule Core.Handler.Tutorial do
  @moduledoc false

  alias Core.Sender
  alias Storage.Service.User
  alias Strings.Tutorial, as: S

  def handle(message) do
    case User.tutorial_step(message.sender) do
      1 -> handle_step_1(message)
      2 -> handle_step_2(message)
      3 -> handle_step_3(message)
      4 -> handle_step_4(message)
      5 -> handle_step_5(message)
    end
  end

  defp normalize(string) do
    string
      |> String.replace(".", "", global: false)
      |> String.trim
      |> String.downcase
  end

  defp handle_step_1(message) do
    key = S.step_1_key()
    next_step_messages = [S.step_2_part_1(), S.step_2_part_2()]
    error = S.step_1_error()

    handle_branch(message, key, next_step_messages, error)
  end

  defp handle_step_2(message) do
    name = User.name(message.sender)

    key = S.step_2_key()
    next_step_messages = [S.step_3_part_1(), S.step_3_part_2(name)]
    error = S.step_2_error()

    handle_branch(message, key, next_step_messages, error)
  end

  defp handle_step_3(message) do
    User.advance_tutorial(message.sender)

    [S.step_4_part_1(), S.step_4_part_2()]
      |> Enum.each(&(Sender.send_command_output(&1, message)))
  end

  defp handle_step_4(message) do
    key = S.step_4_key()
    next_step_messages = [S.step_5()]
    error = S.step_4_error()

    handle_branch(message, key, next_step_messages, error)
  end

  defp handle_step_5(message) do
    key = S.step_5_key()
    next_step_messages = [S.complete_part_1(), S.complete_part_2()]
    error = S.step_5_error()

    handle_branch(message, key, next_step_messages, error)
  end

  defp handle_branch(message, key, next_step_messages, error) do
    if normalize(message.text) == key do
      User.advance_tutorial(message.sender)

      next_step_messages
        |> Enum.each(&(Sender.send_command_output(&1, message)))
    else
      Sender.send_command_output(error, message)
    end
  end
end
