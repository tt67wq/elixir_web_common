defmodule Common.Aliisv.Payment do
  @moduledoc """
  支付宝支付相关api

  配置example
  config :my_app, :pay,
  name: :alipay,
  app_id: "2018xxxxxxxxxxx",
  sign_type: "RSA2",
  notify_url: "https://nanana.cn/notify/alipay_isv",
  seller_id: "",
  app_auth_token: "",
  private_key: "-----BEGIN RSA PRIVATE KEY-----
  xxxxxxxxxx...
  -----END RSA PRIVATE KEY-----",
  ali_public_key: "-----BEGIN PUBLIC KEY-----
  xxxxxxxxxx...
  -----END PUBLIC KEY-----"
  """
  use GenServer
  require Logger
  alias Common.{TimeTool, Crypto, Format, Aliisv.Util}

  @type create_resp :: %{
          alipay_trade_create_response: %{
            code: String.t(),
            msg: String.t(),
            out_trade_no: String.t(),
            trade_no: String.t()
          },
          sign: String.t()
        }
  @type precreate_resp :: %{
          alipay_trade_precreate_response: %{
            code: String.t(),
            msg: String.t(),
            out_trade_no: String.t(),
            qr_code: String.t()
          },
          sign: String.t()
        }

  def start_link(args) do
    {name, args} = Keyword.pop(args, :name, __MODULE__)
    GenServer.start_link(__MODULE__, args, name: name)
  end

  ### api

  @doc """
  普通下单
  """
  @spec create(
          atom(),
          String.t(),
          integer(),
          String.t(),
          String.t(),
          String.t(),
          [map()]
        ) :: create_resp
  def create(server, trade_no, total_amount, buyer_id, subject, body, goods_detail) do
    GenServer.call(
      server,
      {:create,
       [
         out_trade_no: trade_no,
         total_amount: total_amount,
         buyer_id: buyer_id,
         subject: subject,
         body: body,
         goods_detail: goods_detail
       ]}
    )
  end

  @doc """
  生成付款码
  """
  @spec precreate(
          atom(),
          String.t(),
          integer(),
          String.t(),
          String.t(),
          String.t(),
          [map()]
        ) :: precreate_resp
  def precreate(server, trade_no, total_amount, buyer_id, subject, body, goods_detail) do
    GenServer.call(
      server,
      {:precreate,
       [
         out_trade_no: trade_no,
         total_amount: total_amount,
         buyer_id: buyer_id,
         subject: subject,
         body: body,
         goods_detail: goods_detail
       ]}
    )
  end

  @doc """
  查询订单信息
  """
  def query(server, order_no, flag \\ :out) do
    case flag do
      :out -> query_by_out_trade_no(server, order_no)
      :ali -> query_by_trade_no(server, order_no)
    end
  end

  defp query_by_out_trade_no(server, out_trade_no) do
    GenServer.call(server, {:query, [out_trade_no: out_trade_no]})
  end

  defp query_by_trade_no(server, trade_no) do
    GenServer.call(server, {:query, [trade_no: trade_no]})
  end

  @doc """
  退款
  """
  @spec refund(atom(), String.t(), integer(), String.t()) :: %{
          alipay_trade_refund_response: map(),
          sign: String.t()
        }
  def refund(server, trade_no, refund_amount, refund_reason) do
    GenServer.call(server, {
      :refund,
      [
        out_trade_no: trade_no,
        refund_amount: refund_amount,
        refund_reason: refund_reason
      ]
    })
  end

  @spec refund(atom(), String.t(), integer(), String.t(), String.t()) :: %{
          alipay_trade_refund_response: map(),
          sign: String.t()
        }
  def refund(server, trade_no, refund_amount, refund_reason, request_no) do
    GenServer.call(server, {
      :refund,
      [
        out_trade_no: trade_no,
        refund_amount: refund_amount,
        refund_reason: refund_reason,
        out_request_no: request_no
      ]
    })
  end

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
       app_auth_token: Keyword.get(args, :app_auth_token, ""),
       private_key: Keyword.get(args, :private_key),
       ali_public_key: Keyword.get(args, :ali_public_key)
     }}
  end

  @impl true
  def handle_call({:create, args}, _from, state) do
    biz_content = %{
      out_trade_no: Keyword.get(args, :out_trade_no),
      seller_id: state.seller_id,
      buyer_id: Keyword.get(args, :buyer_id),
      total_amount: to_string(Keyword.get(args, :total_amount) / 100),
      discountable_amount: Keyword.get(args, :discountable_amount, 0) / 100,
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
      buyer_id: Keyword.get(args, :buyer_id),
      total_amount: to_string(Keyword.get(args, :total_amount) / 100),
      discountable_amount: Keyword.get(args, :discountable_amount, 0) / 100,
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
        state.app_auth_token,
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
        state.app_auth_token,
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
        state.app_auth_token,
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
end
