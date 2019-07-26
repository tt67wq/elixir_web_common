defmodule Common.Image do
  @moduledoc """
  Some Image tools
  """

  @doc """
  generate qrcode
  """
  @spec qrcode(String.t(), String.t()) :: String.t()
  def qrcode(content, format) do
    body =
      content
      |> EQRCode.encode()
      |> EQRCode.png()
      |> Base.encode64()

    "data:image/#{format};base64," <> body
  end
end
