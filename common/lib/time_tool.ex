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
  def now(format), do: Timex.now(:local) |> Timex.format!(format, :strftime)

  @doc """
  时间戳转为时间字符串

  * stamp  - 时间戳
  * format - 输出格式

  ## Examples

  iex> Common.TimeTool.timestamp_stringfy(1567062547)
  {:ok, "2019-08-29 15:09:07"}
  """
  def timestamp_stringfy(stamp, format \\ "%F %T") do
    timezone = Timezone.get("Asia/Shanghai", Timex.now())
    {:ok, t} = DateTime.from_unix(stamp)

    t
    |> Timezone.convert(timezone)
    |> Timex.format(format, :strftime)
  end

  def timestamp_stringfy!(stamp, format \\ "%F %T") do
    {:ok, str} = timestamp_stringfy(stamp, format)
    str
  end

  @spec time_shift(integer()) :: String.t()
  def time_shift(secs) do
    Timex.now(:local)
    |> Timex.shift(seconds: secs)
    |> Timex.format!("%F %T", :strftime)
  end

  @spec this_year() :: String.t()
  def this_year(), do: Timex.now(:local) |> Timex.format!("%Y", :strftime)

  @doc """
  rfc1123格式输出日期

  ## Examples

  iex> Common.TimeTool.rfc1123_now
  "Sat, 31 Aug 2019 09:58:02 GMT"
  """
  def rfc1123_now do
    :erlang.now()
    |> :calendar.now_to_universal_time()
    |> rfc1123_date
  end

  defp rfc1123_date({{year, month, day}, {hour, minute, second}}) do
    daynumber = :calendar.day_of_the_week({year, month, day})

    "~s, ~2.2.0w ~3.s ~4.4.0w ~2.2.0w:~2.2.0w:~2.2.0w GMT"
    |> :io_lib.format([week(daynumber), day, month(month), year, hour, minute, second])
    |> :lists.flatten()
    |> to_string
  end

  defp week(1), do: 'Mon'
  defp week(2), do: 'Tue'
  defp week(3), do: 'Wed'
  defp week(4), do: 'Thu'
  defp week(5), do: 'Fri'
  defp week(6), do: 'Sat'
  defp week(7), do: 'Sun'

  defp month(1), do: 'Jan'
  defp month(2), do: 'Feb'
  defp month(3), do: 'Mar'
  defp month(4), do: 'Apr'
  defp month(5), do: 'May'
  defp month(6), do: 'Jun'
  defp month(7), do: 'Jul'
  defp month(8), do: 'Aug'
  defp month(9), do: 'Sep'
  defp month(10), do: 'Oct'
  defp month(11), do: 'Nov'
  defp month(12), do: 'Dec'
end
