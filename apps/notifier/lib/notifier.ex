defmodule Notifier do
  @moduledoc false

  use Quantum.Scheduler, otp_app: :notifier
end
