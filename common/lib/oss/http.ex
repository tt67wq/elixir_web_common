defmodule Common.Oss.Http do
  @moduledoc false

  def get(url, headers, options) do
    request(:get, url, "", headers, options)
  end

  def put(url, headers, body, options) do
    request(:put, url, body, headers, options)
  end

  def post(url, headers, body, options) do
    request(:post, url, body, headers, options)
  end

  def delete(url, headers, options) do
    request(:delete, url, "", headers, options)
  end

  def head(url, headers, options) do
    request(:head, url, "", headers, options)
  end

  def request(method, url, body, headers, options) do
    headers =
      Keyword.merge(headers || [],
        user_agent: "elixir_oss_sdk:1.8.2"
      )

    case method do
      :get -> HTTPoison.get!(url, headers, options)
      :put -> HTTPoison.put!(url, body, headers, options)
      :post -> HTTPoison.post!(url, body, headers, options)
      :delete -> HTTPoison.delete!(url, headers, options)
      :head -> HTTPoison.head!(url, headers, options)
    end
  end
end
