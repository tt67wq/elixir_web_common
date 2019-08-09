defmodule Common.Ratelimit do
  @moduledoc false

  use Supervisor
  alias Common.{Crypto, TimeTool}
  @pool_size 5

  #### redis part ####

  def start_link(args) do
    Supervisor.start_link(__MODULE__, args, name: :ratelimit)
  end

  ##### callback
  @impl true
  def init(args) do
    :ets.new(:rate_pool, [
      :set,
      :named_table,
      :public,
      read_concurrency: true,
      write_concurrency: true
    ])

    Supervisor.init(get_workers(args), strategy: :one_for_one)
  end

  defp get_workers(args) do
    for i <- 0..(@pool_size - 1) do
      args = Keyword.put(args, :name, :"ratelimit_#{i}")
      Supervisor.child_spec({Redix, args}, id: {Ratelimit, Crypto.random_string(5)})
    end
  end

  defp command(command) do
    Redix.command(:"ratelimit_#{random_index()}", command)
  end

  defp random_index do
    0..(@pool_size - 1)
    |> Enum.random()
  end

  #### real part ####
  @doc """
  name: 限流器名称
  rate: 每过多少毫秒注入一个新令牌
  size: 桶容量
  """
  @spec register(atom(), integer(), integer()) :: boolean()
  def register(name, rate, size) do
    :ets.insert(:rate_pool, {name, rate, size})
  end

  @spec take_one(atom()) :: boolean()
  def take_one(name) do
    with [{name, rate, size}] <- :ets.lookup(:rate_pool, name),
         ts <- TimeTool.timestamp(:milli_seconds),
         {:ok, od} <- command(["GET", "limiter:#{name}"]),
         od <- fix_num(od),
         counter <- div(ts - od, rate) do
      cond do
        counter <= 0 ->
          false

        counter >= size ->
          command(["SET", "limiter:#{name}", "#{ts - (size - 1) * rate}"])
          true

        :else ->
          command(["SET", "limiter:#{name}", "#{od + rate}"])
          true
      end
    end
  end

  defp fix_num(n) do
    if n == nil do
      0
    else
      String.to_integer(n)
    end
  end
end
