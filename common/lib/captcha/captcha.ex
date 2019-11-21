defmodule Common.Captcha do
  @moduledoc """
  验证码生成库
  """

  @doc """
  生成一个验证码

  * app     - 应用名，需要将编译出的captcha的可执行文件拷贝至应用的priv目录下
  * timeout - 超时时间

  ## Examples

  iex(1)> Common.Captcha.get(:gateway)
  {:ok, "jxanq",
  <<71, 73, 70, 56, 57, 97, 200, 0, 70, 0, 131, 0, 0, 63, 81, 181, 63, 81, 181,
   63, 81, 181, 63, 81, 181, 63, 81, 181, 63, 81, 181, 63, 81, 181, 63, 81, 181,
   63, 81, 181, 63, 81, 181, 63, 81, 181, 63, ...>>}  
  """
  def get(app, timeout \\ 1_000) do
    Port.open({:spawn, Path.join(:code.priv_dir(app), "captcha")}, [:binary])

    # Allow set receive timeout
    receive do
      {_, {:data, data}} ->
        <<text::bytes-size(5), img::binary>> = data
        {:ok, text, img}

      other ->
        other
    after
      timeout ->
        {:timeout}
    end
  end
end
