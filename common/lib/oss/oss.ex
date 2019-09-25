defmodule Common.Oss do
  @moduledoc """
  Oss相关API包装

  ## Config Example
  config :my_app, :oss,
    name: :my_oss,
    endpoint: "oss-cn-hangzhou-internal.aliyuncs.com",
    bucket: "oss-example",
    access_key_id: "xxx",
    access_key_secret: "xxx"
       
  """

  use GenServer
  require Logger
  alias Common.TimeTool

  def start_link(args) do
    {name, args} = Keyword.pop(args, :name, __MODULE__)
    GenServer.start_link(__MODULE__, args, name: name)
  end

  @doc """
  oss文件上传, 返回文件链接

  * server       - name of gen server
  * path         - oss上的路径
  * content_type - 文件属性头
  * body         - 文件字节流

  ## Examples

  iex> {:ok, content} = File.read("/SomePath/58a69a299e6ac.gif")
  {:ok,
   <<71, 73, 70, 56, 57, 97, 80, 0, 80, 0, 230, 116, 0, 20, 20, 20, 253, 253, 253,
     250, 250, 250, 251, 251, 251, 252, 252, 252, 247, 247, 247, 245, 245, 245,
     249, 249, 249, 246, 246, 246, 242, 242, 242, 240, 240, 240, 243, 243, ...>>}
  iex> Common.Oss.upload(:oss, "garbage/gg2.gif", "image/gif", content)      
  "https://s4s-images.oss-cn-shanghai.aliyuncs.com/garbage/gg2.gif"
  """
  def upload(server, path, content_type, body) do
    GenServer.call(server, {:upload, [path: path, content_type: content_type, body: body]})
  end

  #### Server callback

  def init(args) do
    {:ok,
     %{
       endpoint: Keyword.get(args, :endpoint),
       access_key_id: Keyword.get(args, :access_key_id),
       access_key_secret: Keyword.get(args, :access_key_secret),
       bucket: Keyword.get(args, :bucket)
     }}
  end

  def handle_call({:upload, args}, _from, state) do
    body = Keyword.get(args, :body, "")
    path = Keyword.get(args, :path, "")
    date = Keyword.get(args, :date, TimeTool.rfc1123_now())
    content_type = Keyword.get(args, :content_type, "application/x-www-form-urlencoded")
    content_md5 = Keyword.get(args, :content_md5, "")

    headers = Keyword.get(args, :headers, [])

    authorization =
      Common.Oss.Auth.authorization(
        state.access_key_id,
        state.access_key_secret,
        state.bucket,
        path: path,
        date: date,
        method: "PUT",
        content_type: content_type,
        content_md5: content_md5,
        headers: headers
      )

    headers =
      headers
      |> Keyword.put(:Date, date)
      |> Keyword.put(:"Content-Type", content_type)
      |> Keyword.put(:Authorization, authorization)

    url = state.bucket <> "." <> state.endpoint <> "/" <> path
    %HTTPoison.Response{status_code: 200} = Common.Oss.Http.put(url, headers, body, [])

    {:reply, "https://" <> url, state}
  end
end
