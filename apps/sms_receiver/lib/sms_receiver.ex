defmodule SMSReceiver do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      Plug.Adapters.Cowboy.child_spec(:http, SMSReceiver.Router, [], [port: port()])
    ]

    opts = [strategy: :one_for_one, name: SMSReceiver.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp port do
    Application.fetch_env!(:sms_receiver, :port)
  end
end
