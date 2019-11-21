defmodule Common.Aliisv.Util do
  @moduledoc """
  工具函数
  """
  require Logger
  alias Common.{TimeTool, Format}

  # http部分
  def post_request(method, biz_content, notify_url, app_auth_token, state) do
    params = %{
      "app_id" => state.app_id,
      "method" => method,
      "charset" => "utf-8",
      "sign_type" => state.sign_type,
      "timestamp" => TimeTool.now(),
      "version" => "1.0",
      "notify_url" => notify_url,
      "app_auth_token" => app_auth_token,
      "biz_content" => Poison.encode!(biz_content)
    }

    Logger.info("call alipay: #{inspect(params)}")

    headers = [{"Content-type", "application/x-www-form-urlencoded"}]

    with sign <- sign(params, state.private_key, state.sign_type),
         params <- Map.put(params, :sign, sign),
         {biz, params} <- Map.pop(params, "biz_content"),
         req <- URI.encode_query(params),
         body <- URI.encode_query(%{"biz_content" => biz}),
         {:ok, resp} <-
           HTTPoison.post(
             "https://openapi.alipay.com/gateway.do?" <> req,
             body,
             headers
           ),
         %HTTPoison.Response{body: resp_body} <- resp do
      Logger.info(resp_body)
      IO.inspect(resp)
      Poison.decode(resp_body)
    else
      _ -> {:error, "request error"}
    end
  end

  def get_request(method, biz_content, notify_url, app_auth_token, state) do
    params = %{
      "app_id" => state.app_id,
      "method" => method,
      "charset" => "utf-8",
      "sign_type" => state.sign_type,
      "timestamp" => TimeTool.now(),
      "version" => "1.0",
      "notify_url" => notify_url,
      "app_auth_token" => app_auth_token,
      "biz_content" => Poison.encode!(biz_content)
    }

    Logger.info("call alipay: #{inspect(params)}")

    with sign <- sign(params, state.private_key, state.sign_type),
         params <- Map.put(params, :sign, sign),
         req <- URI.encode_query(params),
         {:ok, resp} <-
           HTTPoison.get("https://openapi.alipay.com/gateway.do?" <> req),
         %HTTPoison.Response{body: resp_body} <- resp do
      Logger.info(resp_body)
      Poison.decode(resp_body)
    else
      _ -> {:error, "request error"}
    end
  end

  def get_request_flat(method, biz_content, app_auth_token, state) do
    params = %{
      "app_id" => state.app_id,
      "method" => method,
      "charset" => "utf-8",
      "sign_type" => state.sign_type,
      "timestamp" => TimeTool.now(),
      "version" => "1.0",
      "app_auth_token" => app_auth_token
    }

    with params <- Map.merge(params, biz_content),
         sign <- sign(params, state.private_key, state.sign_type),
         params <- Map.put(params, :sign, sign),
         req <- URI.encode_query(params),
         {:ok, resp} <-
           HTTPoison.get("https://openapi.alipay.com/gateway.do?" <> req),
         %HTTPoison.Response{body: resp_body} <- resp do
      Poison.decode(resp_body)
    else
      _ -> {:error, "request error"}
    end
  end

  # 请求签名
  defp sign(params, private_key, sign_type) do
    string2sign = Format.sort_and_concat(params)

    {:ok, encypted_msg} =
      case sign_type do
        "RSA2" -> RsaEx.sign(string2sign, private_key, :sha256)
        "RSA" -> RsaEx.sign(string2sign, private_key, :sha)
      end

    Base.encode64(encypted_msg)
  end
end
