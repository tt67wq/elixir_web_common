defmodule Common.Aliisv.Mini do
  @moduledoc """
  支付宝小程序相关API

  ## Example
  config :api_2c, :ali_mini,
    name: :xxx,
    desc: "xxx支付宝小程序",
    app_id: "201911076901xxx",
    sign_type: "RSA2",
    private_key: "-----BEGIN RSA PRIVATE KEY-----
    xxxxxxxxxx
    -----END RSA PRIVATE KEY-----",
    ali_public_key: "-----BEGIN PUBLIC KEY-----
    xxxxxxxxxx
    -----END PUBLIC KEY-----"

  """

  use GenServer
  require Logger
  alias Common.{Aliisv.Util}

  def start_link(args) do
    {name, args} = Keyword.pop(args, :name, __MODULE__)
    GenServer.start_link(__MODULE__, args, name: name)
  end

  @doc """
  换取授权访问令牌
  文档: https://docs.open.alipay.com/api_9/alipay.system.oauth.token

  * grant_type    - 值为authorization_code时，代表用code换取；值为refresh_token时，代表用refresh_token换取
  * code          - 授权码，用户对应用授权后得到
  * refresh_token - 刷刷新令牌，上次换取访问令牌时得到。见出参的refresh_token字段

  ## Examples

  iex> Common.Aliisv.Mini.oauth_token(:qcbj, code: "373b3751d2c543b3b3692edc17caNB58")
  {:ok,
   %{
     "alipay_system_oauth_token_response" => %{
       "access_token" => "authbseBde1f782b316247f49ab683967883dX58",
       "alipay_user_id" => "20880012917044689109448892613258",
       "expires_in" => 31536000,
       "re_expires_in" => 31536000,
       "refresh_token" => "authbseBa10d80bf4235488da280b23575309F58",
       "user_id" => "2088702344121581"
     },
     "sign" => "xxx"
   }}
  """
  def oauth_token(server, args), do: GenServer.call(server, {:oauth_token, args})

  @doc """
  获取支付宝会员信息
  文档：https://docs.open.alipay.com/api_2/alipay.user.info.share

  PS: alipay.user.info.share 是“获取会员信息”功能包中使用的 API。“获取会员信息”功能包已于2019 年5月25日升级，在此日期之前未签约“获取会员信息”功能包的小程序无法再调用 alipay.user.info.share

  * auth_token - oauth_token获得的授权令牌

  ## Examples

  iex> Common.Aliisv.Mini.user_info(:qcbj, auth_token: "authbseBde1f782b316247f49ab683967883dX58")
  {:ok, any()}
  """
  def user_info(server, args), do: GenServer.call(server, {:user_info, args})

  ####################################
  ###### SERVER CALLBACKS HEAD

  @impl true
  def init(args) do
    {:ok,
     %{
       app_id: Keyword.get(args, :app_id),
       sign_type: Keyword.get(args, :sign_type),
       seller_id: Keyword.get(args, :seller_id),
       private_key: Keyword.get(args, :private_key),
       ali_public_key: Keyword.get(args, :ali_public_key)
     }}
  end

  @impl true
  def handle_call({:oauth_token, args}, _from, state) do
    biz_content = %{
      grant_type: Keyword.get(args, :grant_type, "authorization_code"),
      code: Keyword.get(args, :code, ""),
      refresh_token: Keyword.get(args, :refresh_token, "")
    }

    res =
      Util.get_request_flat(
        "alipay.system.oauth.token",
        biz_content,
        Keyword.get(args, :app_auth_token, ""),
        state
      )

    {:reply, res, state}
  end

  @impl true
  def handle_call({:user_info, args}, _from, state) do
    biz_content = %{auth_token: Keyword.get(args, :auth_token, "")}

    res =
      Util.get_request_flat(
        "alipay.user.info.share",
        biz_content,
        Keyword.get(args, :app_auth_token, ""),
        state
      )

    {:reply, res, state}
  end
end
