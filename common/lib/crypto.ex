defmodule Common.Crypto do
  @moduledoc """
  加密工具
  """
  @doc """
  md5
  """
  @spec md5(String.t()) :: binary()
  def md5(plaintext), do: :crypto.hash(:md5, plaintext)

  @doc """
  sha1
  """
  @spec sha(String.t()) :: binary()
  def sha(plaintext), do: :crypto.hash(:sha, plaintext)

  @doc """
  sha256
  """
  @spec sha256(String.t()) :: binary()
  def sha256(plaintext), do: :crypto.hash(:sha256, plaintext)

  @spec hmac_sha256(String.t(), String.t()) :: binary()
  def hmac_sha256(key, plaintext), do: :crypto.hmac(:sha256, key, plaintext)

  @doc """
  generate random string
  ## Example

  iex(17)> Common.Crypto.random_string 16
  "2jqDlUxDuOt-qyyZ"
  """
  @spec random_string(integer()) :: String.t()
  def random_string(length) do
    length
    |> :crypto.strong_rand_bytes()
    |> Base.url_encode64()
    |> binary_part(0, length)
  end

  @doc """
  aes加密
  """
  @spec aes_encrypt(String.t(), String.t(), list()) :: binary() | String.t()
  def aes_encrypt(plaintext, key, options \\ [base64: true]) do
    iv = :crypto.strong_rand_bytes(16)
    ciphertext = :crypto.block_encrypt(:aes_cbc256, sha256(key), iv, pkcs7_pad(plaintext))
    res = iv <> ciphertext

    if options[:base64], do: Base.encode64(res), else: res
  end

  # 补全至16字节整数倍
  defp pkcs7_pad(message) do
    bytes_remaining = rem(byte_size(message), 16)
    padding_size = 16 - bytes_remaining
    message <> :binary.copy(<<padding_size>>, padding_size)
  end

  @doc """
  aes解密
  """
  @spec aes_decrypt(String.t(), String.t(), list()) :: String.t()
  def aes_decrypt(ciphertext, key, options \\ [base64: true]) do
    {iv, target} =
      if options[:base64] do
        {:ok, <<iv::binary-16, target::binary>>} = Base.decode64(ciphertext)
        {iv, target}
      else
        <<iv::binary-16, target::binary>> = ciphertext
        {iv, target}
      end

    {:ok, plaintext} =
      :crypto.block_decrypt(:aes_cbc256, sha256(key), iv, target)
      |> pkcs7_unpad()

    plaintext
  end

  defp pkcs7_unpad(<<>>), do: :error

  defp pkcs7_unpad(message) do
    padding_size = :binary.last(message)
    {:ok, binary_part(message, 0, byte_size(message) - padding_size)}
  end

  #### ssl tools
  defp decode_public(nil), do: nil

  defp decode_public(pem) do
    [{:Certificate, der_bin, :not_encrypted}] = :public_key.pem_decode(pem)
    der_bin
  end

  defp decode_private(pem) do
    [{type, der_bin, :not_encrypted}] = :public_key.pem_decode(pem)
    {type, der_bin}
  end

  @spec load_ssl(Keyword.t()) :: [any()]
  def load_ssl([]), do: []

  def load_ssl(ssl) do
    ssl = Enum.into(ssl, %{})

    [
      cacerts: ssl.ca_cert |> decode_public() |> List.wrap(),
      cert: ssl.cert |> decode_public(),
      key: ssl.key |> decode_private()
    ]
    |> Enum.reject(fn {_k, v} -> v == nil end)
  end
end
