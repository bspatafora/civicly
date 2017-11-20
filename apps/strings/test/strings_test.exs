defmodule StringsTest do
  use ExUnit.Case

  alias Strings, as: S
  alias Strings.Tutorial, as: T

  def messages do
    name = String.duplicate("a", 15)
    question = String.duplicate("a", 65)
    title = "After victory in Raqqa over IS, Kurds face tricky peace"
    url = "https://goo.gl/fbsS"

    iteration_start = S.iteration_start([name])
    question = S.question(question)
    partner_deletion = S.partner_deletion(name)
    news = S.news(title, url)

    strings =
      [iteration_start,
       question,
       S.conversation_reminder,
       S.time_warning,
       S.iteration_end,
       S.empty_room,
       S.help,
       S.user_deletion,
       partner_deletion,
       news]

    step_3_part_2 = T.step_3_part_2(name)

    tutorial_strings =
      [T.step_1,
       T.step_1_error,
       T.step_2_part_1,
       T.step_2_part_2,
       T.step_2_error,
       T.step_3_part_1,
       step_3_part_2,
       T.step_3_part_3,
       T.step_4_part_1,
       T.step_4_part_2,
       T.step_4_error,
       T.step_5,
       T.step_5_error,
       T.complete_part_1,
       T.complete_part_2]

    Enum.concat(strings, tutorial_strings)
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
