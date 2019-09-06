defmodule Common.Aliisv.Payment do
  @moduledoc """
  支付宝支付相关api

  ## Example
  config :my_app, :pay,
    name: :alipay,
    app_id: "2018xxxxxxxxxxx",
    sign_type: "RSA2",
    notify_url: "https://nanana.cn/notify/alipay_isv",
    seller_id: "",
    private_key: "-----BEGIN RSA PRIVATE KEY-----
    xxxxxxxxxx...
    -----END RSA PRIVATE KEY-----",
    ali_public_key: "-----BEGIN PUBLIC KEY-----
    xxxxxxxxxx...
    -----END PUBLIC KEY-----"
  """
  use GenServer
  require Logger
  alias Common.{Format, Crypto, Aliisv.Util}

  def start_link(args) do
    {name, args} = Keyword.pop(args, :name, __MODULE__)
    GenServer.start_link(__MODULE__, args, name: name)
  end

  ### api

  @doc """
  普通下单

  参考文档：https://docs.open.alipay.com/api_1/alipay.trade.create

  * server - 服务名
  * args
    * app_auth_token  - 授权商户令牌 若不传，则付钱到主帐号
    * out_trade_no    - 商户订单号
    * buyer_id        - 支付宝帐号
    * total_amount    - 总金额 单位分
    * discount_amount - 可打折金额 单位分
    * subject         - 订单标题
    * body            - 对交易或商品的描述
    * timeout_express - 该笔订单允许的最晚付款时间 20m
    * goods_detail    - 订单包含的商品列表信息
    * notify_url      - 回执地址

  ## Example
  iex> Common.Aliisv.Payment.create(:aliisv, 
    out_trade_no: "test134",    
    app_auth_token: "201905BBc2756c2e07b144ce8dbc746a48177X09",
    buyer_id: "2088202596034906",
    total_amount: 10,
    discount_amount: 0,
    subject: "测试单",
    body: "测试测试"
  )
  {:ok,
   %{
     alipay_trade_create_response: %{
       code: "10000",
       msg: "Success",
       out_trade_no: "test134",
       trade_no: "2019090522001434900576854732"
     },
     sign: "xxx"
   }}
  """
  def create(server, args) do
    GenServer.call(server, {:create, args})
  end

  @doc """
  下单生成待支付链接

  * server - 服务名
  * args
    * app_auth_token  - 授权商户令牌 若不传，则付钱到主帐号
    * out_trade_no    - 商户订单号
    * total_amount    - 总金额 单位分
    * discount_amount - 可打折金额 单位分
    * subject         - 订单标题
    * body            - 对交易或商品的描述
    * timeout_express - 该笔订单允许的最晚付款时间 20m
    * goods_detail    - 订单包含的商品列表信息
    * notify_url      - 回执地址

  ## Examples

  iex> Common.Aliisv.Payment.precreate(:aliisv, 
    out_trade_no: "test135",    
    app_auth_token: "201905BBc2756c2e07b144ce8dbc746a48177X09",
    total_amount: 10,
    discount_amount: 0,
    subject: "测试单",
    body: "测试测试"
  )
  {:ok,
   %{
     alipay_trade_precreate_response: %{
       code: "10000",
       msg: "Success",
       out_trade_no: "test135",
       qr_code: "https://qr.alipay.com/bax082708jnbruc5qj8u800c"
     },
     sign: "tPVvo0LZkAIlUP4rCQ9J7Rj5eH9wkXT5a31Z/TJgL8vsb3u/lL3tvudc2h5Fi7Pgc9wndCgY8WI4Mcob66Isr8otU7IfvQ0k13p0LgHyTd481yW23AVZfGIPpEb93EU5n92rXaNQ46Chq6y1+41RlobvbAQG88lBiPp1pZGeBlM="
   }}
  """
  def precreate(server, args), do: GenServer.call(server, {:precreate, args})

  @doc """
  收银员使用扫码设备读取用户手机支付宝“付款码”/声波获取设备（如麦克风）
  读取用户手机支付宝的声波信息后，
  将二维码或条码信息/声波信息通过本接口上送至支付宝发起支付。

  参考文档：https://docs.open.alipay.com/api_1/alipay.trade.pay/

  * server - 服务名
  * args
    * app_auth_token  - 授权商户令牌 若不传，则付钱到主帐号
    * auth_code       - 支付宝条形码
    * out_trade_no    - 商户订单号
    * total_amount    - 总金额 单位分
    * discount_amount - 可打折金额 单位分
    * subject         - 订单标题
    * body            - 对交易或商品的描述
    * timeout_express - 该笔订单允许的最晚付款时间 20m
    * goods_detail    - 订单包含的商品列表信息
    * notify_url      - 回执地址

  ## Examples

  iex> Common.Aliisv.Payment.scan_pay(:aliisv, 
    out_trade_no: "test137",
    auth_code: "282278693772404227",
    app_auth_token: "201905BBc2756c2e07b144ce8dbc746a48177X09",
    total_amount: 10    ,
    discount_amount: 0,
    subject: "测试单",
    body: "测试测试"
  )
  {:ok,
  %{
    alipay_trade_pay_response: %{
      buyer_logon_id: "tt6***@126.com",
      buyer_pay_amount: "0.10",
      buyer_user_id: "2088202596034906",
      code: "10000",
      fund_bill_list: [%{"amount" => "0.10", "fund_channel" => "PCREDIT"}],
      gmt_payment: "2019-09-05 13:24:43",
      invoice_amount: "0.10",
      msg: "Success",
      out_trade_no: "test137",
      point_amount: "0.00",
      receipt_amount: "0.10",
      total_amount: "0.10",
      trade_no: "2019090522001434900578700599"
    },
    sign: "xxx"
  }}

  iex> Common.Aliisv.Payment.scan_pay(:aliisv, 
    out_trade_no: "test138",
    auth_code: "282278693772404222",
    app_auth_token: "201905BBc2756c2e07b144ce8dbc746a48177X09",
    total_amount: 200000,
    discount_amount: 0,
    subject: "测试单",
    body: "测试测试"
  )
  {:ok,
   %{
     alipay_trade_pay_response: %{
       buyer_logon_id: "tt6***@126.com",
       buyer_pay_amount: "0.00",
       buyer_user_id: "2088202596034906",
       code: "10003",
       invoice_amount: "0.00",
       msg: " order success pay inprocess",
       out_trade_no: "test138",
       point_amount: "0.00",
       receipt_amount: "0.00",
       total_amount: "2000.00",
       trade_no: "2019090522001434900578804384"
     },
     sign: "r9tuLTWGXmzW29goe4dvv9SLp7Mln7gab/Mh6MTCEopMDRf04RYE6zbtWgbK9xWdNI4o6+PUjLe34gXZkwC789+mqYvjuMf5M606NjcBDsLt2aq9ho4KwyD1bjX2vhkbBuS3tue7WL/ncHv0DbCHz7eNjzt2eacGM/h2ybLSrC0="
   }}

  """
  def scan_pay(server, args), do: GenServer.call(server, {:scan_pay, args})

  @doc """
  查询订单

  * server - 服务名
  * args
    * app_auth_token - 授权商户令牌 若不传，则付钱到主帐号
    * trade_no       - 支付宝单号
    * out_trade_no   - 商户单号 与支付宝单号二选一

  ## Examples

  iex> Common.Aliisv.Payment.query(:aliisv, 
     app_auth_token: "201905BBc2756c2e07b144ce8dbc746a48177X09", 
     trade_no: "2019090522001434900576854732"
  )
  {:ok,
   %{
     alipay_trade_query_response: %{
       buyer_logon_id: "tt6***@126.com",
       buyer_pay_amount: "0.00",
       buyer_user_id: "2088202596034906",
       code: "10000",
       invoice_amount: "0.00",
       msg: "Success",
       out_trade_no: "test134",
       point_amount: "0.00",
       receipt_amount: "0.00",
       total_amount: "0.10",
       trade_no: "2019090522001434900576854732",
       trade_status: "WAIT_BUYER_PAY"
     },
     sign: "xxx"
   }}

  iex> Common.Aliisv.Payment.query(:aliisv, 
     app_auth_token: "201905BBc2756c2e07b144ce8dbc746a48177X09", 
     trade_no: "2019090522001434900576854733"
  )
  {:ok,
   %{
     alipay_trade_query_response: %{
       buyer_pay_amount: "0.00",
       code: "40004",
       invoice_amount: "0.00",
       msg: "Business Failed",
       point_amount: "0.00",
       receipt_amount: "0.00",
       sub_code: "ACQ.TRADE_NOT_EXIST",
       sub_msg: "交易不存在"
     },
     sign: "xxx"
   }}
  """
  def query(server, args), do: GenServer.call(server, {:query, args})

  @doc """
  退款

  * server - 服务名
  * args
    * app_auth_token - 授权商户令牌 若不传，则付钱到主帐号
    * trade_no       - 支付宝单号
    * out_trade_no   - 商户单号 与支付宝单号二选一
    * refund_amount  - 退款金额 分
    * refund_reason  - 退款理由
    * out_refund_no  - 退款编号， 不传则随机生成

  ## Examples

  iex> Common.Aliisv.Payment.refund(:aliisv, 
         app_auth_token: "201905BBc2756c2e07b144ce8dbc746a48177X09",
	 out_trade_no: "test135",
	 refund_amount: 1,
	 refund_reason: "test"
  )
  {:ok,
   %{
     alipay_trade_refund_response: %{
       buyer_logon_id: "tt6***@126.com",
       buyer_user_id: "2088202596034906",
       code: "10000",
       fund_change: "Y",
       gmt_refund_pay: "2019-09-05 11:28:16",
       msg: "Success",
       out_trade_no: "test135",
       refund_detail_item_list: [
  %{"amount" => "0.01", "fund_channel" => "PCREDIT"}
       ],
       refund_fee: "0.01",
       send_back_fee: "0.01",
       trade_no: "2019090522001434900578283547"
     },
     sign: "xxx"
   }}
  """
  def refund(server, args), do: GenServer.call(server, {:refund, args})

  @doc """
  验签
  """
  @spec verify(atom, %{required(String.t()) => String.t()}) :: {:ok, boolean}
  def verify(server, params), do: GenServer.call(server, {:verify, params})

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
       private_key: Keyword.get(args, :private_key),
       ali_public_key: Keyword.get(args, :ali_public_key)
     }}
  end

  @impl true
  def handle_call({:create, args}, _from, state) do
    biz_content = %{
      out_trade_no: Keyword.get(args, :out_trade_no),
      seller_id: state.seller_id,
      buyer_id: Keyword.get(args, :buyer_id, ""),
      total_amount: price_to_string(Keyword.get(args, :total_amount, 0)),
      discountable_amount: price_to_string(Keyword.get(args, :discountable_amount, 0)),
      subject: Keyword.get(args, :subject),
      body: Keyword.get(args, :body),
      timeout_express: Keyword.get(args, :timeout_express, "20m"),
      goods_detail: Keyword.get(args, :goods_detail, [])
    }

    res =
      Util.do_request(
        "alipay.trade.create",
        biz_content,
        Keyword.get(args, :notify_url, state.notify_url),
        Keyword.get(args, :app_auth_token, ""),
        state
      )

    {:reply, res, state}
  end

  @impl true
  def handle_call({:precreate, args}, _from, state) do
    biz_content = %{
      out_trade_no: Keyword.get(args, :out_trade_no),
      seller_id: state.seller_id,
      buyer_id: Keyword.get(args, :buyer_id, ""),
      total_amount: price_to_string(Keyword.get(args, :total_amount, 0)),
      discountable_amount: price_to_string(Keyword.get(args, :discountable_amount, 0)),
      subject: Keyword.get(args, :subject),
      body: Keyword.get(args, :body),
      timeout_express: Keyword.get(args, :timeout_express, "20m"),
      goods_detail: Keyword.get(args, :goods_detail, [])
    }

    res =
      Util.do_request(
        "alipay.trade.precreate",
        biz_content,
        Keyword.get(args, :notify_url, state.notify_url),
        Keyword.get(args, :app_auth_token, ""),
        state
      )

    {:reply, res, state}
  end

  @impl true
  def handle_call({:scan_pay, args}, _from, state) do
    biz_content = %{
      out_trade_no: Keyword.get(args, :out_trade_no),
      scene: "bar_code",
      auth_code: Keyword.get(args, :auth_code, ""),
      product_code: Keyword.get(args, :product_code, ""),
      seller_id: state.seller_id,
      buyer_id: Keyword.get(args, :buyer_id, ""),
      total_amount: price_to_string(Keyword.get(args, :total_amount, 0)),
      discountable_amount: price_to_string(Keyword.get(args, :discountable_amount, 0)),
      subject: Keyword.get(args, :subject),
      body: Keyword.get(args, :body),
      timeout_express: Keyword.get(args, :timeout_express, "20m"),
      goods_detail: Keyword.get(args, :goods_detail, [])
    }

    res =
      Util.do_request(
        "alipay.trade.pay",
        biz_content,
        Keyword.get(args, :notify_url, state.notify_url),
        Keyword.get(args, :app_auth_token, ""),
        state
      )

    {:reply, res, state}
  end

  @impl true
  def handle_call({:refund, args}, _from, state) do
    biz_content = %{
      out_trade_no: Keyword.get(args, :out_trade_no, ""),
      trade_no: Keyword.get(args, :trade_no, ""),
      refund_amount: Keyword.get(args, :refund_amount, 0) / 100,
      refund_reason: Keyword.get(args, :refund_reason, "退款"),
      out_request_no: Keyword.get(args, :out_request_no, Crypto.random_string(12))
    }

    res =
      Util.do_request(
        "alipay.trade.refund",
        biz_content,
        Keyword.get(args, :notify_url, state.notify_url),
        Keyword.get(args, :app_auth_token, ""),
        state
      )

    {:reply, res, state}
  end

  @impl true
  def handle_call({:query, args}, _from, state) do
    biz_content = %{
      out_trade_no: Keyword.get(args, :out_trade_no, ""),
      trade_no: Keyword.get(args, :trade_no, "")
    }

    res =
      Util.do_request(
        "alipay.trade.query",
        biz_content,
        Keyword.get(args, :notify_url, state.notify_url),
        Keyword.get(args, :app_auth_token, ""),
        state
      )

    {:reply, res, state}
  end

  @impl true
  def handle_call({:verify, params}, _from, state) do
    {sign, params} = Map.pop(params, "sign")
    {sign_type, params} = Map.pop(params, "sign_type")

    sign_type_map = %{"RSA" => :sha, "SA2" => :sha256}

    string2sign =
      params
      |> Format.sort_and_concat()

    Logger.info(string2sign)

    {:reply,
     RsaEx.verify(
       string2sign,
       Base.decode64!(sign),
       state.ali_public_key,
       Map.get(sign_type_map, sign_type)
     ), state}
  end

  defp price_to_string(price), do: :erlang.float_to_binary(price / 100.0, decimals: 2)
end
