defmodule Core.Action.End do
  @moduledoc false

  alias Core.Sender
  alias Storage.EngagementLevelService
  alias Storage.Service
  alias Storage.Service.Conversation
  alias Strings, as: S

  def execute do
    EngagementLevelService.update_all()

    Enum.each(Service.active_users(), fn user ->
      text = S.iteration_end(user.engagement_level)
      recipients = [user.phone]

      Sender.send_message(text, recipients)
    end)

    Conversation.inactivate_all()
  end
end
