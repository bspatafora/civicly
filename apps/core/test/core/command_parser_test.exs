defmodule Core.CommandParserTest do
  use ExUnit.Case, async: true

  alias Core.CommandParser
  alias Strings, as: S

  test "it returns the command name and data of a valid :add command" do
    text = "#{S.add_command()} Test User 5555555555"

    {command, name, phone} = CommandParser.parse(text)

    assert command == :add
    assert name == "Test User"
    assert phone == "5555555555"
  end

  test "it returns :invalid when a command is unknown" do
    text = ":unknown Test User 5555555555"

    assert {:invalid} = CommandParser.parse(text)
  end

  test "it returns :invalid when an :add command contains no data" do
    assert {:invalid} = CommandParser.parse(S.add_command())
  end

  test "it returns :invalid when an :add command contains no name" do
    text = "#{S.add_command()} 5555555555"

    assert {:invalid} = CommandParser.parse(text)
  end

  test "it returns :invalid when an :add command contains no phone" do
    text = "#{S.add_command()} Test User"

    assert {:invalid} = CommandParser.parse(text)
  end

  test "it returns :invalid when an :add command is reversed" do
    text = "#{S.add_command()} 5555555555 Test User"

    assert {:invalid} = CommandParser.parse(text)
  end

  test "it returns :invalid when an :add command contains a phone that is too long" do
    text = "#{S.add_command()} Test User 15555555555"

    assert {:invalid} = CommandParser.parse(text)
  end

  test "it returns :invalid when an :add command contains a phone that is too short" do
    text = "#{S.add_command()} Test User 5555555"

    assert {:invalid} = CommandParser.parse(text)
  end

  test "it returns the command name and data of a valid :msg command" do
    text = "#{S.msg_command()} 5555555555 Test message"

    {command, phone, text} = CommandParser.parse(text)

    assert command == :msg
    assert phone == "5555555555"
    assert text == "Test message"
  end

  test "it returns :invalid when a :msg command contains no data" do
    assert {:invalid} = CommandParser.parse(S.msg_command())
  end

  test "it returns :invalid when a :msg command contains no phone" do
    text = "#{S.msg_command()} Test message"

    assert {:invalid} = CommandParser.parse(text)
  end

  test "it returns :invalid when a :msg command contains no text" do
    text = "#{S.msg_command()} 5555555555"

    assert {:invalid} = CommandParser.parse(text)
  end

  test "it returns :invalid when a :msg command is reversed" do
    text = "#{S.msg_command()} Test message 5555555555"

    assert {:invalid} = CommandParser.parse(text)
  end

  test "it returns :invalid when a :msg command contains a phone that is too long" do
    text = "#{S.msg_command()} 15555555555 Test message"

    assert {:invalid} = CommandParser.parse(text)
  end

  test "it returns :invalid when a :msg command contains a phone that is too short" do
    text = "#{S.msg_command()} 5555555 Test message"

    assert {:invalid} = CommandParser.parse(text)
  end

  test "it returns the command name and data of a valid :new command" do
    text = "#{S.new_command()} 123 Test question?"

    {command, number, question} = CommandParser.parse(text)

    assert command == :new
    assert number == "123"
    assert question == "Test question?"
  end

  test "it returns :invalid when a :new command contains no data" do
    assert {:invalid} = CommandParser.parse(S.new_command())
  end

  test "it returns :invalid when a :new command contains no number" do
    text = "#{S.new_command()} Test question?"

    assert {:invalid} = CommandParser.parse(text)
  end

  test "it returns :invalid when a :new command contains no question" do
    text = "#{S.new_command()} 123"

    assert {:invalid} = CommandParser.parse(text)
  end

  test "it returns :invalid when a :new command's question has no question mark" do
    text = "#{S.new_command()} 123 Test question"

    assert {:invalid} = CommandParser.parse(text)
  end

  test "it returns :invalid when a :new command is reversed" do
    text = "#{S.new_command()} Test question? 123"

    assert {:invalid} = CommandParser.parse(text)
  end

  test "it returns the command name of a valid :end command" do
    assert CommandParser.parse(S.end_command()) == :end
  end
end
