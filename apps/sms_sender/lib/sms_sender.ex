defmodule SMSSender do
  @moduledoc false

  alias SMSSender.RateLimitedSender
  alias SMSSender.Sender

  def send(message) do
    env = Application.get_env(:sms_sender, :env)
    if env == :prod do
      RateLimitedSender.send(message)
    else
      Sender.send(message)
    end
  end
end
