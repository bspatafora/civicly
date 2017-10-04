defmodule Core.CommandParserTest do
  use ExUnit.Case, async: true

  alias Core.CommandParser
  alias Strings, as: S

  test "parse/1 returns :invalid when a command is unknown" do
    text = ":unknown Test User 5555555555"

    assert {:invalid} = CommandParser.parse(text)
  end

  test "parse/1 returns the command name and data of a valid :add command" do
    text = "#{S.add_command()} Test User 5555555555"

    {command, name, phone} = CommandParser.parse(text)

    assert command == :add
    assert name == "Test User"
    assert phone == "5555555555"
  end

  test "parse/1 returns :invalid when an :add command contains no data" do
    text = S.add_command()

    assert {:invalid} = CommandParser.parse(text)
  end

  test "parse/1 returns :invalid when an :add command contains no name" do
    text = "#{S.add_command()} 5555555555"

    assert {:invalid} = CommandParser.parse(text)
  end

  test "parse/1 returns :invalid when an :add command contains no phone" do
    text = "#{S.add_command()} Test User"

    assert {:invalid} = CommandParser.parse(text)
  end

  test "parse/1 returns :invalid when an :add command is reversed" do
    text = "#{S.add_command()} 5555555555 Test User"

    assert {:invalid} = CommandParser.parse(text)
  end

  test "parse/1 returns :invalid when an :add command contains a phone that is too long" do
    text = "#{S.add_command()} Test User 15555555555"

    assert {:invalid} = CommandParser.parse(text)
  end

  test "parse/1 returns :invalid when an :add command contains a phone that is too short" do
    text = "#{S.add_command()} Test User 5555555"

    assert {:invalid} = CommandParser.parse(text)
  end

  test "parse/1 returns the command name and data of a valid :msg command" do
    text = "#{S.msg_command()} 5555555555 Test message"

    {command, phone, text} = CommandParser.parse(text)

    assert command == :msg
    assert phone == "5555555555"
    assert text == "Test message"
  end

  test "parse/1 returns :invalid when a :msg command contains no data" do
    text = S.msg_command()

    assert {:invalid} = CommandParser.parse(text)
  end

  test "parse/1 returns :invalid when a :msg command contains no phone" do
    text = "#{S.msg_command()} Test message"

    assert {:invalid} = CommandParser.parse(text)
  end

  test "parse/1 returns :invalid when a :msg command contains no text" do
    text = "#{S.msg_command()} 5555555555"

    assert {:invalid} = CommandParser.parse(text)
  end

  test "parse/1 returns :invalid when a :msg command is reversed" do
    text = "#{S.msg_command()} Test message 5555555555"

    assert {:invalid} = CommandParser.parse(text)
  end

  test "parse/1 returns :invalid when a :msg command contains a phone that is too long" do
    text = "#{S.msg_command()} 15555555555 Test message"

    assert {:invalid} = CommandParser.parse(text)
  end

  test "parse/1 returns :invalid when a :msg command contains a phone that is too short" do
    text = "#{S.msg_command()} 5555555 Test message"

    assert {:invalid} = CommandParser.parse(text)
  end

  test "parse/1 returns the command name and data of a valid :new command" do
    text = "#{S.new_command()} Test question?"

    {command, question} = CommandParser.parse(text)

    assert command == :new
    assert question == "Test question?"
  end

  test "parse/1 returns :invalid when a :new command contains no data" do
    text = S.new_command()

    assert {:invalid} = CommandParser.parse(text)
  end

  test "parse/1 returns :invalid when a :new command's question has no question mark" do
    text = "#{S.new_command()} Test question"

    assert {:invalid} = CommandParser.parse(text)
  end

  test "parse/1 returns the command name and data of a valid :notify command" do
    text = "#{S.notify_command()} Test question?"

    {command, question} = CommandParser.parse(text)

    assert command == :notify
    assert question == "Test question?"
  end

  test "parse/1 returns :invalid when a :notify command contains no data" do
    text = S.notify_command()

    assert {:invalid} = CommandParser.parse(text)
  end

  test "parse/1 returns :invalid when a :notify command's question has no question mark" do
    text = "#{S.notify_command()} Test question"

    assert {:invalid} = CommandParser.parse(text)
  end

  test "parse/1 returns the command name of an :end command" do
    assert CommandParser.parse(S.end_command()) == :end
  end

  test "parse/1 returns the command name and data of an :all command" do
    text = "#{S.all_command()} Test message"

    {command, text} = CommandParser.parse(text)

    assert command == :all
    assert text == "Test message"
  end

  test "parse/1 returns the command name and data of an :all_active command" do
    text = "#{S.all_active_command()} Test message"

    {command, text} = CommandParser.parse(text)

    assert command == :all_active
    assert text == "Test message"
  end

  test "parse/1 returns the command name of a :news command" do
    assert CommandParser.parse(S.news_command()) == :news
  end

  test "parse/1 returns the command name of a :news_check command" do
    assert CommandParser.parse(S.news_check_command()) == :news?
  end
end
