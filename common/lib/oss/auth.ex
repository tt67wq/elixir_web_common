defmodule Common.Oss.Auth do
  @moduledoc """
  Authorization module

  Document about signature: https://help.aliyun.com/document_detail/31951.html

  """
  alias Common.TimeTool

  def authorization(access_key_id, access_key_secret, bucket, options) do
    "OSS " <> access_key_id <> ":" <> signature(access_key_secret, bucket, options)
  end

  def signature(access_key_secret, bucket, options) do
    path = Keyword.fetch!(options, :path)
    method = Keyword.fetch!(options, :method)
    content_type = Keyword.fetch!(options, :content_type)
    content_md5 = Keyword.get(options, :content_md5, "")
    date = Keyword.get(options, :date, TimeTool.rfc1123_now())
    headers = Keyword.get(options, :headers, [])

    canonicalized_oss_resource = canonicalized_oss_resource(bucket, path)
    canonicalized_oss_headers = canonicalize_oss_headers(headers)

    str =
      method <>
        "\n" <>
        content_md5 <>
        "\n" <>
        content_type <>
        "\n" <>
        date <>
        "\n" <>
        canonicalized_oss_headers <>
        canonicalized_oss_resource

    :crypto.hmac(:sha, access_key_secret, str)
    |> :base64.encode_to_string()
    |> to_string
  end

  defp canonicalized_oss_resource(bucket, path), do: "/#{bucket}/#{path}"

  defp canonicalize_oss_headers(headers) do
    headers =
      Enum.filter(headers, fn
        {"x-oss-" <> _, _} -> true
        _ -> false
      end)

    canonicalize_oss_headers(headers, "")
  end

  defp canonicalize_oss_headers([], canonical), do: canonical

  defp canonicalize_oss_headers([{key, value} | rest], canonical) do
    canonicalize_oss_headers(rest, "#{canonical}#{key}:#{value}\n")
  end
end
