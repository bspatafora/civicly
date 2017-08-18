defmodule Strings do
  def iteration_start(partner_names) do
    partner_names = Enum.join(partner_names, " and ")
    "Say hello to #{partner_names}!"
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
