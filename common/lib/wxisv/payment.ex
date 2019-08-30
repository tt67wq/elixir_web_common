defmodule Common.Wxisv.Payment do
  @moduledoc """
  微信服务商模式支付相关API


  配置示例
  config :my_app, :pay,
  name: :wxisv,
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
  alias Common.{Crypto, Wxisv.Util}

  def start_link(args) do
    {name, args} = Keyword.pop(args, :name, __MODULE__)
    GenServer.start_link(__MODULE__, args, name: name)
  end

  @doc """
  统一下单
  商户系统先调用该接口在微信支付服务后台生成预支付交易单，
  返回正确的预支付交易会话标识后再按Native、JSAPI、APP等不同场景生成交易串调起支付

  * server           - name of genserver
  * sub_mch_id       - 微信支付分配的子商户号
  * body             - 商品或支付单简要描述，格式要求：门店品牌名-城市分店名-实际商品名称
  * detail           - 单品优惠功能字段
  * out_trade_no     - 商户自定义单号
  * total_fee        - 总价，单位为分
  * spbill_create_ip - 终端IP
  * notify_url       - 结果回调地址
  * trade_type       - 支付方式 JSAPI -JSAPI支付 NATIVE -Native支付 APP -APP支付
  * product_id       - trade_type=NATIVE时，此参数必传。此id为二维码中包含的商品ID，商户自行定义。
  * openid           - trade_type=JSAPI，此参数必传，用户在主商户appid下的唯一标识。openid和sub_openid可以选传其中之一，如果选择传sub_openid,则必须传sub_appid
  * sub_openid       - trade_type=JSAPI，此参数必传，用户在主商户appid下的唯一标识。openid和sub_openid可以选传其中之一，如果选择传sub_openid,则必须传sub_appid

  ## Examples
  """
  def unifiedorder(
        server,
        sub_mch_id,
        body,
        detail,
        out_trade_no,
        total_fee,
        spbill_create_ip,
        notify_url,
        trade_type,
        product_id,
        openid,
        sub_openid
      ) do
    GenServer.call(
      server,
      {:unifiedorder,
       [
         sub_mch_id: sub_mch_id,
         body: body,
         detail: detail,
         out_trade_no: out_trade_no,
         total_fee: total_fee,
         spbill_create_ip: spbill_create_ip,
         notify_url: notify_url,
         trade_type: trade_type,
         product_id: product_id,
         openid: openid,
         sub_openid: sub_openid
       ]}
    )
  end

  @doc """
  收银员使用扫码设备读取微信用户付款码以后，二维码或条码信息会传送至商户收银台，
  由商户收银台或者商户后台调用该接口发起支付。

  * server           - name of genserver
  * sub_mch_id       - 微信支付分配的子商户号
  * body             - 商品或支付单简要描述，格式要求：门店品牌名-城市分店名-实际商品名称
  * detail           - 单品优惠功能字段
  * out_trade_no     - 商户自定义单号
  * total_fee        - 总价，单位为分
  * spbill_create_ip - 终端IP
  * auth_code        - 扫码支付授权码，设备读取用户微信中的条码或者二维码信息

  ## Examples

  iex> Common.Wxisv.Payment.micropay(:wxisv, "1487469312", "image形象店-深圳腾大-QQ公仔", "", "s4stest1234", 10, "220.184.130.30", "134680050634385495")
  {:ok,
  %{
     appid: "wxa06cadd4aa4ad40f",
     err_code: "USERPAYING",
     err_code_des: "需要用户输入支付密码",
     mch_id: "1424355602",
     nonce_str: "k7zK9ey5MGsicrFe",
     result_code: "FAIL",
     return_code: "SUCCESS",
     return_msg: "OK",
     sign: "E5CD0972C2632DD10D3CF6CF980CA87D",
     sub_mch_id: "1487469312"
  }}

  """
  def micropay(
        server,
        sub_mch_id,
        body,
        detail,
        out_trade_no,
        total_fee,
        spbill_create_ip,
        auth_code
      ) do
    GenServer.call(
      server,
      {:micropay,
       [
         sub_mch_id: sub_mch_id,
         body: body,
         detail: detail,
         out_trade_no: out_trade_no,
         total_fee: total_fee,
         spbill_create_ip: spbill_create_ip,
         auth_code: auth_code
       ]}
    )
  end

  @doc """
  根据商户单号查询订单

  * server       - name of genserver
  * out_trade_no - 商户自定义订单号 

  ## Examples

  iex> Common.Wxisv.Payment.query_out(:wxisv, "1487469312", "s4stest1235")
  {:ok,
  %{
     appid: "wxa06cadd4aa4ad40f",
     attach: "",
     bank_type: "CFT",
     cash_fee: "1",
     cash_fee_type: "CNY",
     fee_type: "CNY",
     is_subscribe: "Y",
     mch_id: "1424355602",
     nonce_str: "2irt2TRYpGeIvVPC",
     openid: "oKrTMwYZRSB1e4zBpvaZy6UXmzpI",
     out_trade_no: "s4stest1235",
     result_code: "SUCCESS",
     return_code: "SUCCESS",
     return_msg: "OK",
     sign: "52A4E89376094256CF5A88E46F3FC2F0",
     sub_mch_id: "1487469312",
     time_end: "20190829115402",
     total_fee: "1",
     trade_state: "SUCCESS",
     trade_state_desc: "支付成功",
     trade_type: "MICROPAY",
     transaction_id: "4200000372201908290017282113"
  }}

  """
  def query_out(server, sub_mch_id, out_trade_no) do
    GenServer.call(server, {:query, [sub_mch_id: sub_mch_id, out_trade_no: out_trade_no]})
  end

  def query_wx(server, sub_mch_id, transaction_id) do
    GenServer.call(server, {:query, [sub_mch_id: sub_mch_id, transaction_id: transaction_id]})
  end

  def refund_order(server, out_trade_no, total_fee, refund_fee) do
    GenServer.call(
      server,
      {:refund, [out_trade_no: out_trade_no, total_fee: total_fee, refund_fee: refund_fee]}
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

  @impl true
  def handle_call({:micropay, args}, _from, state) do
    params = %{
      appid: state.appid,
      mch_id: state.mch_id,
      sub_mch_id: Keyword.get(args, :sub_mch_id, ""),
      body: Keyword.get(args, :body, ""),
      detail: Keyword.get(args, :detail, ""),
      out_trade_no: Keyword.get(args, :out_trade_no, ""),
      total_fee: Keyword.get(args, :total_fee, 0),
      spbill_create_ip: Keyword.get(args, :spbill_create_ip, ""),
      auth_code: Keyword.get(args, :auth_code, "")
    }

    {:reply, Util.do_request("/pay/micropay", params, state), state}
  end

  @impl true
  def handle_call({:unifiedorder, args}, _from, state) do
    params = %{
      appid: state.appid,
      mch_id: state.mch_id,
      sub_mch_id: Keyword.get(args, :sub_mch_id, ""),
      body: Keyword.get(args, :body, ""),
      detail: Keyword.get(args, :detail, ""),
      out_trade_no: Keyword.get(args, :out_trade_no, ""),
      total_fee: Keyword.get(args, :total_fee, 0),
      spbill_create_ip: Keyword.get(args, :spbill_create_ip, ""),
      notify_url: Keyword.get(args, :notify_url, state.notify_url),
      trade_type: Keyword.get(args, :trade_type, ""),
      product_id: Keyword.get(args, :product_id, ""),
      openid: Keyword.get(args, :openid, ""),
      sub_openid: Keyword.get(args, :sub_openid, "")
    }

    {:reply, Util.do_request("/pay/unifiedorder", params, state), state}
  end

  @impl true
  def handle_call({:query, args}, _from, state) do
    params = %{
      appid: state.appid,
      mch_id: state.mch_id,
      sub_mch_id: Keyword.get(args, :sub_mch_id, ""),
      transaction_id: Keyword.get(args, :transaction_id, ""),
      out_trade_no: Keyword.get(args, :out_trade_no, "")
    }

    {:reply, Util.do_request("/pay/orderquery", params, state), state}
  end

  @impl true
  def handle_call({:refund, args}, _from, state) do
    params = %{
      appid: state.appid,
      mch_id: state.mch_id,
      sub_mch_id: Keyword.get(args, :sub_mch_id, ""),
      transaction_id: Keyword.get(args, :transaction_id, ""),
      out_trade_no: Keyword.get(args, :out_trade_no, ""),
      total_fee: Keyword.get(args, :total_fee, 0),
      out_refund_no: Crypto.random_string(12),
      refund_fee: Keyword.get(args, :refund_fee, 0)
    }

    {:reply, Util.do_request("/secapi/pay/refund", params, state), state}
  end
end
