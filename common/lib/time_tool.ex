defmodule Common.TimeTool do
  @moduledoc """
  时间相关工具
  """

  use Timex

  @doc """
  get current timestamp
  ## Example
  iex> Common.TimeTool.timestamp(:seconds)
  1534466694
  iex> Common.TimeTool.timestamp(:milli_seconds)
  1534466732335
  iex> Common.TimeTool.timestamp(:micro_seconds)
  1534466750683862
  iex> Common.TimeTool.timestamp(:nano_seconds)
  1534466778949821000
  """
  @spec timestamp(atom()) :: integer
  def timestamp(typ \\ :seconds), do: :os.system_time(typ)

  @doc """
  get current time string
  ## Example

  iex> Common.TimeTool.now
  "2018-08-17 09:25:46"
  """
  @spec now() :: String.t()
  def now, do: Timex.now(:local) |> Timex.format!("%F %T", :strftime)

  @doc """
  时间字符串转换为时间戳
  """
  @spec to_timestamp(String.t(), String.t()) :: integer()
  def to_timestamp(strftime, format \\ "%F %T") do
    stamp =
      strftime
      |> Timex.parse!(format, :strftime)
      |> DateTime.from_naive!("Etc/UTC")
      |> DateTime.to_unix()

    # 改为本地
    stamp - 8 * 3600
  end

  @spec time_shift(integer()) :: String.t()
  def time_shift(secs) do
    Timex.now(:local)
    |> Timex.shift(seconds: secs)
    |> Timex.format!("%F %T", :strftime)
  end

  @spec this_year() :: String.t()
  def this_year(), do: Timex.now(:local) |> Timex.format!("%Y", :strftime)
end
