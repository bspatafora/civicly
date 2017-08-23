defmodule Strings do
  @moduledoc false

  def reminders do
    """
    Remember:
    1. Attacking evokes defensiveness; better to ask, listen, offer
    2. We can't get better if we're shut
    3. Fortune favors the bold (and curious)
    """
  end

  def iteration_start(partners, question, year) do
    partners = Enum.join(partners, " and ")

    """
    Welcome to iteration #{year}! You're connected to #{partners}.

    Question for you: #{question}
    """
  end

  def stop_request do
    "stop"
  end

  def command_prefix do
    ":"
  end

  def add_command do
    command_prefix() <> "add"
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
