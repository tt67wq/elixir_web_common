defmodule Common.Pullword do
  @moduledoc """
  中文分词

  参考文档 
  1. http://api.pullword.com/

  """

  @doc """
  在线分词
  用的http://api.pullword.com/

  * content - 等待分词的内容

  ## Examples

  iex> Common.Pullword.online_pullword("马云也要喊我爸爸")
  ["马云", "云也", "我爸", "爸爸"]
  """
  def online_pullword(content) do
    {:ok, resp} =
      HTTPoison.get("http://api.pullword.com/get.php?source=#{content}&param1=0.5&param2=0")

    case resp do
      %HTTPoison.Response{status_code: 200, body: body} ->
        body
        |> String.split("\r\n")
        |> Enum.filter(fn x -> x != "" end)

      _ ->
        [content]
    end
  end

  @doc """
  本地执行一个python脚本来分词, 需要将pullword.py放到宿主机的PATH下

  * content - 等待分词的内容
  * timeout - 超时时间 默认3s

  ## Examples

  iex> Common.Pullword.local_pullword("马云也要喊我爸爸")
  {:ok, ["马云", "也", "要", "喊", "我", "爸爸"]}
  """
  def local_pullword(content, timeout \\ 3000) do
    Port.open({:spawn, "pullword.py #{content}"}, [:binary])

    receive do
      {_, {:data, res}} -> {:ok, String.split(res, "\n") |> Enum.filter(fn x -> x != "" end)}
      other -> other
    after
      timeout -> :timeout
    end
  end
end
