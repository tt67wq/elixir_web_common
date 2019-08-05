defmodule Common.Wxisv.Payment do
  @moduledoc """
  微信支付相关API

  配置示例
  config :my_app, :pay,
  name: :wx,
  appid: "wx123456",
  mch_id: "123456",
  key: "9ot34qkz0o9qxo4tvdjp9g98um4xxxxx",
  app_secret: "be8e3bb33e377fba6ae528573b39a389",
  notify_url: "https://something.cn/notify/wxpay_isv",
  sign_type: "MD5",
  ssl: [
    ca_cert: nil,
    cert: "-----BEGIN CERTIFICATE-----
    xxx
    -----END CERTIFICATE-----",
    key: "-----BEGIN PRIVATE KEY-----
    xxx
    -----END PRIVATE KEY-----"
  ]
  """
  use GenServer
  require Logger
  alias Common.{Crypto, Format, Xml}

  @gateway "https://api.mch.weixin.qq.com"

  def start_link(args) do
    {name, args} = Keyword.pop(args, :name, __MODULE__)
    GenServer.start_link(__MODULE__, args, name: name)
  end

  def query_order(server, order_no) do
    GenServer.call(server, {:query, [out_trade_no: order_no]})
  end

  def refund_order(server, order_no, total_fee, refund_fee) do
    GenServer.call(
      server,
      {:refund, [out_trade_no: order_no, total_fee: total_fee, refund_fee: refund_fee]}
    )
  end

  ####### SERVER CALLBACK

  @impl true
  def init(args) do
    {:ok,
     %{
       appid: Keyword.get(args, :appid),
       mch_id: Keyword.get(args, :mch_id),
       key: Keyword.get(args, :key, ""),
       app_secret: Keyword.get(args, :app_secret),
       notify_url: Keyword.get(args, :notify_url, ""),
       sign_type: Keyword.get(args, :sign_type, "MD5"),
       ssl: Keyword.get(args, :ssl, [])
     }}
  end

  # 签名
  defp sign(params, key, sign_type) do
    string2sign =
      params
      |> Enum.into(%{}, fn {k, v} -> {to_string(k), v} end)
      |> Format.sort_and_concat(true)

    string2sign = string2sign <> "&key=#{key}"
    # Logger.info("base string ==> #{string2sign}")

    case sign_type do
      "MD5" -> Crypto.md5(string2sign) |> Base.encode16(case: :upper)
      "HMAC-SHA256" -> Crypto.hmac_sha256(key, string2sign) |> Base.encode16(case: :upper)
    end
  end

  defp do_request(method, params, state) do
    headers = [{"Content-type", "application/x-www-form-urlencoded"}]

    with params <- Map.put(params, :nonce_str, Crypto.random_string(16)),
         params <- Map.put(params, :sign, sign(params, state.key, state.sign_type)),
         {:ok, resp} <-
           HTTPoison.post(@gateway <> method, Format.map2xml(params), headers,
             ssl: Crypto.load_ssl(state.ssl)
           ),
         %HTTPoison.Response{body: resp_body} <- resp do
      Xml.parse(resp_body)
    end
  end

  @impl true
  def handle_call({:query, args}, _from, state) do
    params = %{
      appid: state.appid,
      mch_id: state.mch_id,
      transaction_id: Keyword.get(args, :transaction_id, ""),
      out_trade_no: Keyword.get(args, :out_trade_no, "")
    }

    {:reply, do_request("/pay/orderquery", params, state), state}
  end

  @impl true
  def handle_call({:refund, args}, _from, state) do
    params = %{
      appid: state.appid,
      mch_id: state.mch_id,
      transaction_id: Keyword.get(args, :transaction_id, ""),
      out_trade_no: Keyword.get(args, :out_trade_no, ""),
      total_fee: Keyword.get(args, :total_fee, 0),
      out_refund_no: Crypto.random_string(12),
      refund_fee: Keyword.get(args, :refund_fee, 0)
    }

    {:reply, do_request("/secapi/pay/refund", params, state), state}
  end
end
