defmodule Common.Aliisv.Smapp do
  @moduledoc """
  支付宝相关api
  """
  use GenServer
  require Logger
  alias Common.{TimeTool, Format}

  def start_link(args) do
    {name, args} = Keyword.pop(args, :name, __MODULE__)
    GenServer.start_link(__MODULE__, args, name: name)
  end

  ### api

  @doc """
  订单同步
  """
  @spec order_sync(atom, String.t(), String.t(), String.t(), integer, [map()]) :: map
  def order_sync(server, trade_no, out_biz_no, buyer_id, amount, ext_info) do
    GenServer.call(
      server,
      {:sync,
       [
         out_biz_no: out_biz_no,
         trade_no: trade_no,
         buyer_id: buyer_id,
         amount: amount,
         ext_info: ext_info
       ]}
    )
  end

  ####################################
  ###### SERVER CALLBACKS HEAD

  @impl true
  def init(args) do
    {:ok,
     %{
       app_id: Keyword.get(args, :app_id),
       sign_type: Keyword.get(args, :sign_type),
       notify_url: Keyword.get(args, :notify_url, ""),
       seller_id: Keyword.get(args, :seller_id),
       app_auth_token: Keyword.get(args, :app_auth_token, ""),
       private_key: Keyword.get(args, :private_key),
       ali_public_key: Keyword.get(args, :ali_public_key)
     }}
  end

  # 订单同步
  @impl true
  def handle_call({:sync, args}, _from, state) do
    biz_content = %{
      out_biz_no: Keyword.get(args, :out_biz_no),
      trade_no: Keyword.get(args, :trade_no),
      seller_id: state.seller_id,
      buyer_id: Keyword.get(args, :buyer_id),
      partner_id: state.seller_id,
      amount: Keyword.get(args, :amount, 0) / 100,
      ext_info: Keyword.get(args, :ext_info)
    }

    res =
      do_request(
        "alipay.merchant.order.sync",
        biz_content,
        Keyword.get(args, :notify_url, state.notify_url),
        state.app_auth_token,
        state
      )

    {:reply, res, state}
  end

  ######### 私有函数部分 ##############

  # 通用请求行为
  defp do_request(method, biz_content, _notify_url, app_auth_token, state) do
    params = %{
      app_id: state.app_id,
      method: method,
      charset: "utf-8",
      sign_type: state.sign_type,
      timestamp: TimeTool.now(),
      version: "1.0",
      format: "json",
      # notify_url: notify_url,
      biz_content: Poison.encode!(biz_content)
    }

    params =
      if app_auth_token != "", do: Map.put(params, :app_auth_token, app_auth_token), else: params

    full_params =
      params
      |> Map.put(:sign, sign(params, state.private_key, state.sign_type))

    IO.inspect(full_params)
    
    %HTTPotion.Response{body: respBody} =
      HTTPotion.get("https://openapi.alipay.com/gateway.do", query: full_params)

    respBody
    |> Poison.decode!()
    |> Format.stringkey2atom()
  end

  # 请求签名
  defp sign(params, private_key, sign_type) do
    string2sign =
      params
      |> Enum.into(%{}, fn {k, v} -> {to_string(k), v} end)
      |> Format.sort_and_concat()

    {:ok, encypted_msg} =
      case sign_type do
        "RSA2" -> RsaEx.sign(string2sign, private_key, :sha256)
        "RSA" -> RsaEx.sign(string2sign, private_key, :sha)
      end

    Base.encode64(encypted_msg)
  end
end
