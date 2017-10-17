defmodule Strings do
  @moduledoc false

  # Accepts multiple partners, but currently written for one
  def iteration_start(partners) do
    partners = Enum.join(partners, " and ")

    """
    #{civicly()} Now connected to #{partners}, your compatriot for the next 4 days.

    Remember, we're all here because we believe in civic, civil conversation.
    """
  end

  def question(question) do
    """
    #{civicly()} Here's a question to get things rolling. Be bold: Send the first text!

    #{question}
    """
  end

  def iteration_end do
    """
    #{civicly()} The round has ended. You'll get a text when the next one begins.

    Type "Help" for help
    """
  end

  def empty_room do
    """
    #{civicly()} Sorry, but there's no one to send that message to right now! You'll be connected with someone when the next round begins.

    Type "Help" for help
    """
  end

  def help do
    """
    #{civicly()} Have a question? Visit civicly.us/welcome or email me at ben@civicly.us.

    Type "Stop" to immediately and permanently delete your account.
    """
  end

  def user_deletion do
    """
    #{civicly()} Your account has been deleted.

    Please send one last text with your reason for leaving. It would be a huge help.
    """
  end

  def partner_deletion(name) do
    """
    #{civicly()} #{name}'s account has been deleted.

    You'll be connected to someone new when the next round begins.

    Type "Help" for help
    """
  end

  def news(title, url) do
    "#{civicly()} (Reuters) #{title} #{url}"
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

  def all_command do
    command_prefix() <> "all!"
  end

  def all_active_command do
    command_prefix() <> "all"
  end

  def new_command do
    command_prefix() <> "new"
  end

  def notify_command do
    command_prefix() <> "notify"
  end

  def end_command do
    command_prefix() <> "end"
  end

  def news_command do
    command_prefix() <> "news"
  end

  def news_check_command do
    command_prefix() <> "news?"
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
