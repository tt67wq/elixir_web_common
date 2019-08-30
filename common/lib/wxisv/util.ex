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
      Xml.parse(resp_body)
    end
  end
end
