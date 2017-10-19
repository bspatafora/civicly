defmodule Core.Action.News do
  @moduledoc false

  alias Core.APIClient.{Googl, NewsAPI}
  alias Core.Sender
  alias Strings, as: S

  def check(message) do
    Sender.send_command_output(news(), message)
  end

  def send(message) do
    Sender.send_to_active(news(), message)
  end

  def send do
    Sender.send_to_active(news())
  end

  defp news do
    {headline, url} = NewsAPI.reuters_top()
    S.news(headline, Googl.shorten(url))
  end
end
