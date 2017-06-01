defmodule Core.CommandParserTest do
  use ExUnit.Case, async: true

  alias Core.CommandParser

  test "a valid add command returns the command name and data" do
    text = ":add Test User 5555555555"

    {command, name, phone} = CommandParser.parse(text)

    assert command == :add
    assert name == "Test User"
    assert phone == "5555555555"
  end

  test "an unknown command returns :invalid" do
    text = ":unknown Test User 5555555555"

    assert {:invalid} = CommandParser.parse(text)
  end

  test "an add command with no data returns :invalid" do
    text = ":add"

    assert {:invalid} = CommandParser.parse(text)
  end
end
