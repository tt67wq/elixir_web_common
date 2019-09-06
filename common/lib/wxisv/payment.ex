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
  * args
    * sub_mch_id       - 微信支付分配的子商户号
    * body             - 商品或支付单简要描述，格式要求：门店品牌名-城市分店名-实际商品名称
    * detail           - 单品优惠功能字段
    * out_trade_no     - 商户自定义单号
    * total_fee        - 总价，单位为分
    * create_ip        - 终端IP
    * notify_url       - 结果回调地址
    * trade_type       - 支付方式 JSAPI -JSAPI支付 NATIVE -Native支付 APP -APP支付
    * product_id       - trade_type=NATIVE时，此参数必传。此id为二维码中包含的商品ID，商户自行定义。
    * openid           - trade_type=JSAPI，此参数必传，用户在主商户appid下的唯一标识。openid和sub_openid可以选传其中之一，如果选择传sub_openid,则必须传sub_appid
    * sub_openid       - trade_type=JSAPI，此参数必传，用户在主商户appid下的唯一标识。openid和sub_openid可以选传其中之一，如果选择传sub_openid,则必须传sub_appid

  ## Examples
  iex> args = [
    body: "测试单",
    create_ip: "192.168.16.125",
    detail: "",
    notify_url: "https://mys4s.cn/grey/v5/print_call",
    out_trade_no: "test1122",
    product_id: "11223344",
    sub_mch_id: "1487469312",
    total_fee: 10,
    trade_type: "NATIVE"
  ]
  iex> Common.Wxisv.Payment.unifiedorder(:wxisv, args)
  {:ok,
   %{
     appid: "wxa06cadd4aa4ad40f",
     code_url: "weixin://wxpay/bizpayurl?pr=EbeGUSZ",
     mch_id: "1424355602",
     nonce_str: "QFmzTNeisSXriBNs",
     prepay_id: "wx0316512846043232656b28471971382700",
     result_code: "SUCCESS",
     return_code: "SUCCESS",
     return_msg: "OK",
     sign: "8171B33BA395DD52F30F495DC74155E4",
     sub_mch_id: "1487469312",
     trade_type: "NATIVE"
   }}
  """
  def unifiedorder(server, args) do
    GenServer.call(server, {:unifiedorder, args})
  end

  @doc """
  收银员使用扫码设备读取微信用户付款码以后，二维码或条码信息会传送至商户收银台，
  由商户收银台或者商户后台调用该接口发起支付。

  * server           - name of genserver
  * args
    * sub_mch_id       - 微信支付分配的子商户号
    * body             - 商品或支付单简要描述，格式要求：门店品牌名-城市分店名-实际商品名称
    * detail           - 单品优惠功能字段
    * out_trade_no     - 商户自定义单号
    * total_fee        - 总价，单位为分
    * spbill_create_ip - 终端IP
    * auth_code        - 扫码支付授权码，设备读取用户微信中的条码或者二维码信息

  ## Examples
  iex> args = [
    sub_mch_id: "1487469312",
    body: "image形象店-深圳腾大-QQ公仔",
    detail: "",
    out_trade_no: "test112233",
    total_fee: 10,
    create_ip: "192.168.16.125",
    auth_code: "134680050634385495"
  ]
  iex> Common.Wxisv.Payment.micropay(:wxisv, args)
  {:ok,
    %{
      appid: "wxa06cadd4aa4ad40f",
      err_code: "AUTH_CODE_INVALID",
      err_code_des: "101 付款码无效，请重新扫码",
      mch_id: "1424355602",
      nonce_str: "ehAjAkUkEAjCNnHp",
      result_code: "FAIL",
      return_code: "SUCCESS",
      return_msg: "OK",
      sign: "C1F0ED4911F4C61DFE2C39AF661BC232",
      sub_mch_id: "1487469312"
    }
  }
  """
  def micropay(server, args) do
    GenServer.call(server, {:micropay, args})
  end

  @doc """
  查询订单

  * server       - name of genserver
  * args
    * sub_mch_id   - 子商户号
    * out_trade_no - 商户自定义订单号 
    * transaction_id - 微信单号 与 商户自定义订单号 二选一

  ## Examples

  iex> Common.Wxisv.Payment.query(:wxisv, [sub_mch_id: "1487469312", out_trade_no: "s4stest1235"])
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
  def query(server, args) do
    GenServer.call(server, {:query, args})
  end

  @doc """
  退款申请

  * server         - name of genserver
  * args
    * sub_mch_id     - 子商户号
    * out_trade_no   - 商户订单号
    * transaction_id - 微信单号 与 商户订单号二选一
    * total_fee      - 订单总额 单位分
    * refund_fee     - 退款金额 单位分

  ## Examples
  iex> args = [
    sub_mch_id: "1487469312",
    out_trade_no: "test112",
    transaction_id: "",
    total_fee: 10,
    refund_fee: 1
  ]
  iex> Common.Wxisv.Payment.refund(:wxisv, args)
  {:ok,
   %{
     appid: "wxa06cadd4aa4ad40f",
     cash_fee: "10",
     cash_refund_fee: "1",
     coupon_refund_count: "0",
     coupon_refund_fee: "0",
     mch_id: "1424355602",
     nonce_str: "cqmkJaMJrjzl1wwH",
     out_refund_no: "EL7gVvPTqg9M",
     out_trade_no: "test112",
     refund_channel: "",
     refund_fee: "1",
     refund_id: "50000101662019090211990249580",
     result_code: "SUCCESS",
     return_code: "SUCCESS",
     return_msg: "OK",
     sign: "D3810FFE7A34FC38FA8DCAA99EDFA1E3",
     sub_mch_id: "1487469312",
     total_fee: "10",
     transaction_id: "4200000381201909026741897025"
   }}

  """
  def refund(server, args) do
    GenServer.call(server, {:refund, args})
  end

  @doc """
  关闭订单

  * server - 服务名
  * args
    * sub_mch_id     - 子商户号
    * out_trade_no   - 商户订单号

  ## Examples

  iex> Common.Wxisv.Payment.close(:wxisv, sub_mch_id: "1487469312", out_trade_no: "OD201909031737204363")
  {:ok,
   %{
     appid: "wxa06cadd4aa4ad40f",
     mch_id: "1424355602",
     nonce_str: "ntATMURgcF5jndJr",
     result_code: "SUCCESS",
     return_code: "SUCCESS",
     return_msg: "OK",
     sign: "AA2AD1F8D9EE2BBA6EC7640ED21A28CD",
     sub_mch_id: "1487469312"
   }}

  """
  def close(server, args) do
    GenServer.call(server, {:close, args})
  end

  @doc """
  微信回执签名校验

  * params - 微信回执的map

  ## Examples

  iex> params = %{
    appid: "wxa06cadd4aa4ad40f",
    bank_type: "CFT",
    cash_fee: "10",
    fee_type: "CNY",
    is_subscribe: "Y",
    mch_id: "1424355602",
    nonce_str: "7HKXdkhXHfXXWQ6J",
    openid: "oKrTMwYZRSB1e4zBpvaZy6UXmzpI",
    out_trade_no: "OD201909041001229424",
    result_code: "SUCCESS",
    return_code: "SUCCESS",
    sign: "B0DFB4AE298220A71298A19D55D65B25",
    sub_mch_id: "1487469312",
    time_end: "20190904100236",
    total_fee: "10",
    trade_type: "NATIVE",
    transaction_id: "4200000391201909043698367230"
  }

  iex> Common.Wxisv.Payment.verify(:wxisv, params)
  true
  """
  def verify(server, params) do
    GenServer.call(server, {:verify, params})
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

  @impl true
  def handle_call({:close, args}, _from, state) do
    params = %{
      appid: state.appid,
      mch_id: state.mch_id,
      sub_mch_id: Keyword.get(args, :sub_mch_id, ""),
      out_trade_no: Keyword.get(args, :out_trade_no, "")
    }

    {:reply, Util.do_request("/pay/closeorder", params, state), state}
  end

  @impl true
  def handle_call({:verify, params}, _from, state) do
    {:reply, Util.verify(params, state.key, state.sign_type), state}
  end
end
