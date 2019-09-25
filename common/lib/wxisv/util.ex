defmodule Common.Wxisv.Util do
  @moduledoc false
  alias Common.{Crypto, Format, Xml}

  @gateway "https://api.mch.weixin.qq.com"

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

  def do_request(method, params, state) do
    headers = [{"Content-type", "application/x-www-form-urlencoded"}]

    with params <- Map.put(params, :nonce_str, Crypto.random_string(16)),
         params <- Map.put(params, :sign, sign(params, state.key, state.sign_type)),
         {:ok, resp} <-
           HTTPoison.post(@gateway <> method, Format.map2xml(params), headers,
             ssl: Crypto.load_ssl(state.ssl)
           ),
         %HTTPoison.Response{body: resp_body} <- resp do
      {:ok, Xml.naive_map(resp_body) |> Map.fetch!("xml")}
    end
  end

  @doc """
  验证微信回执的签名是否为真

  * params    - 微信回执的xml转换的map
  * key       - 用户密钥
  * sign_type - 签名方法 MD5 或 HMAC-SHA256

  ## Examples

  iex> params = %{
    "appid" => "wxa06cadd4aa4ad40f",
    "bank_type" => "CFT",
    "cash_fee" => "10",
    "fee_type" => "CNY",
    "is_subscribe" => "Y",
    "mch_id" => "1424355602",
    "nonce_str" => "7HKXdkhXHfXXWQ6J",
    "openid" => "oKrTMwYZRSB1e4zBpvaZy6UXmzpI",
    "out_trade_no" => "OD201909041001229424",
    "result_code" => "SUCCESS",
    "return_code" => "SUCCESS",
    "sign" => "B0DFB4AE298220A71298A19D55D65B25",
    "sub_mch_id" => "1487469312",
    "time_end" => "20190904100236",
    "total_fee" => "10",
    "trade_type" => "NATIVE",
    "transaction_id" => "4200000391201909043698367230"
  }
  iex> Common.Wxisv.Util.verify(params, "9ot34qkz0o9qxo4tvdjp9g98um4zw9wx", "MD5")
  true
  """
  def verify(params, key, sign_type) do
    {wx_sign, params} = Map.pop(params, "sign")

    case sign(params, key, sign_type) do
      ^wx_sign -> true
      _ -> {:error, "sign not match"}
    end
  end
end
