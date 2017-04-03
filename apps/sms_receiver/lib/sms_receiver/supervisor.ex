defmodule SMSReceiver.Supervisor do
  use Application
  @port Application.get_env(:sms_receiver, :port)

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      Plug.Adapters.Cowboy.child_spec(:http, SMSReceiver, [], [port: @port])
    ]

    opts = [strategy: :one_for_one, name: SMSReceiver.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
