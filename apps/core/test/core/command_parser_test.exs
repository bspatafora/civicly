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

  test "it returns invalid when an :add command contains no data" do
    text = "#{S.add_command()}"

    assert {:invalid} = CommandParser.parse(text)
  end

  test "it returns an empty name when an :add command contains no name" do
    text = "#{S.add_command()} 5555555555"

    {command, name, phone} = CommandParser.parse(text)

    assert command == :add
    assert name == ""
    assert phone == "5555555555"
  end

  test "it returns an empty name and the name as the phone when an :add command contains no phone" do
    text = "#{S.add_command()} Test User"

    {command, name, phone} = CommandParser.parse(text)

    assert command == :add
    assert name == ""
    assert phone == "Test User"
  end
end
