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
    out_trade_no: "test133",    
    app_auth_token: "201909BBa2c7b81e394d4127b03083ce29decX80",
    buyer_id: "2088202596034906",
    total_amount: 10,
    discount_amount: 0,
    subject: "测试单",
    body: "测试测试"
  )
  {:ok,
   %{
     "alipay_trade_create_response" => %{
       "code" => "10000",
       "msg" => "Success",
       "out_trade_no" => "test133",
       "trade_no" => "2019092022001434900554038366"
     },
     "sign" => "xxx"
   }} 
  """
  def create(server, args) do
    GenServer.call(server, {:create, args})
  end

  @doc """
  下单生成待支付链接
  参考文档：https://docs.open.alipay.com/api_1/koubei.trade.order.precreate

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
    app_auth_token: "201909BBa2c7b81e394d4127b03083ce29decX80",
    total_amount: 10,
    discount_amount: 0,
    subject: "测试单",
    body: "测试测试"
  )
  {:ok,
   %{
     "alipay_trade_precreate_response" => %{
       "code" => "10000",
       "msg" => "Success",
       "out_trade_no" => "test135",
       "qr_code" => "https://qr.alipay.com/bax06108fsv0jl1vbseb001d"
     },
     "sign" => "xxx"
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
    app_auth_token: "201909BBa2c7b81e394d4127b03083ce29decX80",
    total_amount: 10    ,
    discount_amount: 0,
    subject: "测试单",
    body: "测试测试"
  )
  {:ok,
   %{
     "alipay_trade_pay_response" => %{
       "buyer_logon_id" => "tt6***@126.com",
       "buyer_pay_amount" => "0.00",
       "buyer_user_id" => "2088202596034906",
       "code" => "10003",
       "invoice_amount" => "0.00",
       "msg" => " order success pay inprocess",
       "out_trade_no" => "test137",
       "point_amount" => "0.00",
       "receipt_amount" => "0.00",
       "total_amount" => "0.10",
       "trade_no" => "2019092022001434900552365166"
     },
     "sign" => "xxx"
   }}

  """
  def scan_pay(server, args), do: GenServer.call(server, {:scan_pay, args})

  @doc """
  查询订单
  参考文档：https://docs.open.alipay.com/api_1/koubei.trade.itemorder.query

  * server - 服务名
  * args
    * app_auth_token - 授权商户令牌 若不传，则付钱到主帐号
    * trade_no       - 支付宝单号
    * out_trade_no   - 商户单号 与支付宝单号二选一

  ## Examples

  iex> Common.Aliisv.Payment.query(:aliisv, app_auth_token: "201909BBa2c7b81e394d4127b03083ce29decX80", trade_no: "2019101022001434900569339350")
  {:ok,
   %{
     "alipay_trade_query_response" => %{
       "buyer_pay_amount" => "0.00",
       "code" => "40004",
       "invoice_amount" => "0.00",
       "msg" => "Business Failed",
       "point_amount" => "0.00",
       "receipt_amount" => "0.00",
       "sub_code" => "ACQ.TRADE_NOT_EXIST",
       "sub_msg" => "交易不存在"
     },
     "sign" => "xxx" 
   }}
  """
  def query(server, args), do: GenServer.call(server, {:query, args})

  @doc """
  退款
  参考文档：https://docs.open.alipay.com/api_1/koubei.trade.itemorder.refund

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
    app_auth_token: "201909BBa2c7b81e394d4127b03083ce29decX80",
    out_trade_no: "test135",
    refund_amount: 1,
    refund_reason: "test"
  )
  %{
    "alipay_trade_refund_response" => %{
      "buyer_logon_id" => "tt6***@126.com",
      "buyer_user_id" => "2088202596034906",
      "code" => "10000",
      "fund_change" => "Y",
      "gmt_refund_pay" => "2019-10-15 16:47:58",
      "msg" => "Success",
      "out_trade_no" => "OD201910151643581919",
      "refund_detail_item_list" => [
  %{"amount" => "0.01", "fund_channel" => "PCREDIT"}
      ],
      "refund_fee" => "0.03",
      "send_back_fee" => "0.01",
      "trade_no" => "2019101522001434901401309763"
    },
    "sign" => "xxx"
  }
  """
  def refund(server, args), do: GenServer.call(server, {:refund, args})

  @doc """
  验签
  """
  @spec verify(atom, %{required(String.t()) => String.t()}) :: {:ok, boolean}
  def verify(server, params), do: GenServer.call(server, {:verify, params})

  @doc """
  换取应用授权令牌
  参考文档: https://docs.open.alipay.com/api_9/alipay.open.auth.token.app

  * args
    * grant_type    - authorization_code表示换取app_auth_token, refresh_token表示刷新app_auth_token
    * code          - 授权码，如果grant_type的值为authorization_code。该值必须填写
    * refresh_token - 刷新令牌，如果grant_type值为refresh_token。该值不能为空

  ## Examples

  iex> Common.Aliisv.Payment.auth_token(:aliisv, grant_type: "authorization_code", code: "Pd249b0134ca84db494338cc958f4590")

  """
  def auth_token(server, args), do: GenServer.call(server, {:auth_token, args})

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
      Util.get_request(
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
      Util.get_request(
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
      Util.get_request(
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
      Util.get_request(
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
      Util.get_request(
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

    sign_type_map = %{"RSA" => :sha, "RSA2" => :sha256}

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

  @impl true
  def handle_call({:auth_token, args}, _from, state) do
    biz_content = %{
      grant_type: Keyword.get(args, :grant_type, "authorization_code"),
      code: Keyword.get(args, :code, ""),
      refresh_token: Keyword.get(args, :refresh_token, "")
    }

    res =
      Util.get_request(
        "alipay.open.auth.token.app",
        biz_content,
        Keyword.get(args, :notify_url, state.notify_url),
        Keyword.get(args, :app_auth_token, ""),
        state
      )

    {:reply, res, state}
  end

  defp price_to_string(price), do: :erlang.float_to_binary(price / 100.0, decimals: 2)
end
