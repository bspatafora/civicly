defmodule StringsTest do
  use ExUnit.Case

  alias Strings, as: S

  def messages do
    name = String.duplicate("a", 15)
    question = String.duplicate("a", 65)
    number = "1234"

    iteration_start = S.iteration_start([name], question, number)
    partner_deletion = S.partner_deletion(name)

    [S.welcome,
     S.reminders,
     iteration_start,
     S.iteration_end,
     S.empty_room,
     S.help,
     S.user_deletion,
     partner_deletion]
  end

  test "no message is longer than 160 characters" do
    messages()
      |> Enum.each(&(assert String.length(&1) <= 160))
  end

  test "no message contains smart quotes" do
    smart_quotes = ["‘", "’", "“", "”"]

    messages()
      |> Enum.each(&(assert String.contains?(&1, smart_quotes) == false))
  end
end
