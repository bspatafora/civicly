defmodule Core.APIClient.NewsAPI do
  @moduledoc false

  alias Core.APIClient.APIClient

  def reuters_top do
    key = get_config(:news_api_key)
    path = "/v1/articles?source=reuters&sortBy=top&apiKey=#{key}"
    url = get_config(:news_api_origin) <> path

    response_body = APIClient.get!(url)

    top_story = get_top_story(response_body)
    {get_title(top_story), get_url(top_story)}
  end

  defp get_config(key) do
    Application.get_env(:core, key)
  end

  defp get_top_story(body) do
    stories = Map.fetch!(body, "articles")
    stories = remove_special_reports(stories)
    List.first(stories)
  end

  defp remove_special_reports(stories) do
    special_report_prefix = "Special Report:"
    special_report? =
      fn(story) ->
        title = Map.fetch!(story, "title")
        String.starts_with?(title, special_report_prefix)
      end

    stories |> Enum.reject(special_report?)
  end

  defp get_title(story) do
    Map.fetch!(story, "title")
  end

  defp get_url(story) do
    Map.fetch!(story, "url")
  end
end
