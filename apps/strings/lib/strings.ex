defmodule Strings do
  @moduledoc false

  def welcome do
    """
    Thank you for joining civicly!

    When the next round starts, you'll be connected with another American.

    Type HELP for help, or STOP to be removed
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

  def iteration_start(partners, question, year) do
    partners = Enum.join(partners, " and ")

    """
    Welcome to iteration #{year}! You're connected to #{partners}.

    Question for you: #{question}
    """
  end

  def iteration_end do
    """
    The current round has ended. You'll be notified when the next one starts.
    """
  end

  def between_iterations do
    """
    We're between rounds right now. You'll be notified when the next one starts.

    Type HELP for help
    """
  end

  def help do
    """
    Have a question? Visit civicly.us or email me at ben@civicly.us

    Type STOP to be removed
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
    "Invalid command"
  end

  def insert_failed do
    "Insert failed"
  end

  def user_added(name) do
    "Added #{name}"
  end

  def user_deletion do
    "You have been deleted"
  end

  def partner_deletion(name) do
    "#{name} has quit"
  end

  def prepend_name(name, text) do
    "#{name}: #{text}"
  end
end
