defmodule SMSSender do
  @moduledoc false

  require Logger

  alias Storage.Service

  @headers [{"Content-type", "application/json; charset=UTF-8"}]

  @spec send(SMSMessage.t) :: no_return()
  def send(message) do
    body = Poison.encode!(%{
      recipient: message.recipient,
      text: message.text})

    attempt_to_send(message, body, 1)
  end

  defp attempt_to_send(message, body, attempt) do
    if attempt == 7 do
      log_send_failure(message)
    else
      message = Service.refresh_sms_relay_ip(message)
      url = url(message.sms_relay_ip)

      case post(body, url) do
        {:ok, _} ->
          log_send(message)
        {:error, _} ->
          seconds_delay = round(:math.pow(attempt, 2))
          :timer.sleep(seconds_delay * 1000)

          attempt_to_send(body, message, attempt + 1)
      end
    end
  end

  defp post(body, url) do
    HTTPoison.post(url, body, @headers)
  end

  defp url(host) do
    host <> ":" <> get_config(:port) <> get_config(:path)
  end

  defp get_config(key) do
    Application.get_env(:sms_sender, key)
  end

  defp log_send(message) do
    log(message, "SMS sent", "SMSSent")
  end

  defp log_send_failure(message) do
    log(message, "SMS failed to send", "SMSSendFailure")
  end

  defp log(message, log_message, log_name) do
    Logger.info(log_message, [
      name: log_name,
      recipient: message.recipient,
      sender: message.sender,
      sms_relay_ip: message.sms_relay_ip,
      text: message.text,
      timestamp: message.timestamp,
      uuid: message.uuid])
  end
end
