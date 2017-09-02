defmodule Strings do
  @moduledoc false

  def welcome do
    """
    Thank you for joining civicly!

    When the next round starts, you'll be connected with another American.

    Type HELP for help, or STOP to delete your account
    """
  end

  def reminders do
    """
    Remember:
    1. Attacking evokes defensiveness; better to ask, listen, offer
    2. We can't get better if we're shut
    3. Fortune favors the bold and curious
    """
  end

  def iteration_start(partners, number, question) do
    partners = Enum.join(partners, " and ")

    """
    #{civicly()} Welcome to round #{number}. Say hello to #{partners}!

    Here's a question: #{question}
    """
  end

  def iteration_end do
    """
    #{civicly()} The current round has ended. You'll be notified when the next one begins.
    """
  end

  def empty_room do
    """
    #{civicly()} There's no one to send that message to right now! You'll be connected with someone when the next round begins.

    Type HELP for help
    """
  end

  def help do
    """
    #{civicly()} Have a question? Visit civicly.us or email me at ben@civicly.us

    Type STOP to delete your account
    """
  end

  def user_deletion do
    """
    #{civicly()} Your account has been deleted.

    To rejoin, email me at ben@civicly.us
    """
  end

  def partner_deletion(name) do
    """
    #{civicly()} #{name} has deleted their account. Maybe it was an accident?

    You'll be connected with a new partner when the next round begins.
    """
  end

  def stop_request do
    "STOP"
  end

  def help_request do
    "HELP"
  end

  def command_prefix do
    ":"
  end

  def add_command do
    command_prefix() <> "add"
  end

  def msg_command do
    command_prefix() <> "msg"
  end

  def new_command do
    command_prefix() <> "new"
  end

  def end_command do
    command_prefix() <> "end"
  end

  def invalid_command do
    "#{civicly()} Invalid command"
  end

  def insert_failed do
    "#{civicly()} Insert failed"
  end

  def user_added(name) do
    "#{civicly()} Added #{name}"
  end

  def civicly do
    "[civicly]"
  end

  def prepend_civicly(text) do
    "#{civicly()} #{text}"
  end
end
