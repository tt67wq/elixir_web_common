defmodule Common.Rpc do
  @moduledoc false

  import Common.Crypto, only: [random_string: 1]
  alias Common.TimeTool
  require Logger

  @doc """
  rpc 调用，包装了下erlang自带的rpc能力
  NOTE: 
    1. 所有的RPC方法都要在Interface模块中定义好，否则无法调用
    2. Interface中的方法必须标明出入参

  * module     - Interface中模块名
  * method     - 方法名
  * data       - rpc调用的body，必须严格按照Interface方法的要求来
  * request_id - 调用日志标记

  ## Examples

  iex> Module.some_function(args1, args2)
  {:ok, any()}
  """
  @spec do_rpc(atom(), atom(), String.t(), any()) :: any()
  def do_rpc(module, method, data, request_id) do
    Logger.metadata(request_id: request_id)
    start_stamp = TimeTool.timestamp(:milli_seconds)
    Logger.info("#{module}.#{method} BEGIN: data => #{inspect(data)}")
    res = apply(module, method, [%{request_id: request_id, data: data}])

    Logger.info(
      "#{module}.#{method} END: Timeuse => #{TimeTool.timestamp(:milli_seconds) - start_stamp}ms"
    )

    res
  end

  def do_rpc(module, method, data),
    do: do_rpc(module, method, data, random_string(8))

  @doc """
  调用微服务的数据抽取，并设置日志元数据
  """
  def fetch_data(attrs) do
    {request_id, %{data: data}} = Map.pop(attrs, :request_id)
    Logger.metadata(request_id: request_id)
    {request_id, data}
  end
end
