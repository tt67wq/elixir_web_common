defmodule Common.Aliisv.Util do
  @moduledoc """
  工具函数
  """
  alias Common.{TimeTool, Crypto, Format}
  # 通用请求行为
  def do_request(method, biz_content, notify_url, app_auth_token, state) do
    params = %{
      app_id: state.app_id,
      method: method,
      charset: "utf-8",
      sign_type: state.sign_type,
      timestamp: TimeTool.now(),
      version: "1.0",
      notify_url: notify_url,
      biz_content: Poison.encode!(biz_content)
    }

    params =
      if app_auth_token != "", do: Map.put(params, :app_auth_token, app_auth_token), else: params

    headers = [{"Content-type", "application/x-www-form-urlencoded"}]

    with sign <- sign(params, state.private_key, state.sign_type),
         params <- Map.put(params, :sign, sign),
         req <- URI.encode_query(params),
         {:ok, resp} <-
           HTTPoison.get(
             "https://openapi.alipay.com/gateway.do?" <> req,
             headers
           ),
         %HTTPoison.Response{body: resp_body} <- resp do
      resp_body
      |> Poison.decode!()
      |> Format.stringkey2atom()
    end
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
