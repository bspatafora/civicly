defmodule Core.Helpers do
  alias Plug.Parsers
  alias Storage.Helpers

  defmodule MessageSpy do
    def new do
      Agent.start_link(fn -> [] end)
    end

    def record(agent, recipient, text) do
      Agent.update(agent, &([%{recipient: recipient, text: text} | &1]))
    end

    def get(agent) do
      Agent.get(agent, &(&1))
    end
  end

  def build_message(params) do
    message = %SMSMessage{
      recipient: Helpers.random_phone(),
      sender: Helpers.random_phone(),
      sms_relay_ip: "localhost",
      text: "Test message",
      timestamp: DateTime.utc_now(),
      uuid: Helpers.uuid()}

    Map.merge(message, params)
  end

  def parse_body_params(conn) do
    opts = Parsers.init([parsers: [:json], json_decoder: Poison])
    Parsers.call(conn, opts)
  end
end
