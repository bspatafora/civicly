defmodule SMSSender.Supervisor do
  @moduledoc false

  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      worker(SMSSender.RateLimitedSender, [])
    ]

    opts = [strategy: :one_for_one, name: SMSSender.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
