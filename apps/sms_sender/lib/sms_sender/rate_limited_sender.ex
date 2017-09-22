defmodule SMSSender.RateLimitedSender do
  @moduledoc false

  use GenServer

  alias SMSSender.Sender

  # Client

  def start_link do
    GenServer.start_link(__MODULE__, :ok, name: :sender)
  end

  def send(message) do
    GenServer.cast(:sender, {:send, message})
  end

  # Server

  def init(:ok) do
    rate_limit = Application.get_env(:sms_sender, :rate_limit)
    :timer.send_interval(rate_limit, :tick)
    {:ok, :queue.new}
  end

  def handle_cast({:send, message}, queue) do
    {:noreply, :queue.in(message, queue)}
  end

  def handle_info(:tick, queue) do
    send_sms(:queue.out(queue))
  end

  defp send_sms({:empty, queue}) do
    {:noreply, queue}
  end

  defp send_sms({{:value, message}, queue}) do
    Sender.send(message)
    {:noreply, queue}
  end
end
