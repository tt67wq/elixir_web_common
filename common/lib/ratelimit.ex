defmodule Common.Ratelimit do
  @moduledoc """
  令牌桶限流器，基于Redis存储

  ## Config Example
  ```
  config :my_app, :ratelimit,
    host: "localhost",
    port: 6379
  ```

  ## Usage
  ```
  def start(_type, _args) do
    children = [
      {Ratelimit, Application.get_env(:my_app, :ratelimit)}
    ]

    children = children ++ payment_worker() ++ caches()
    opts = [strategy: :one_for_one, name: MyApp.Supervisor]
    Supervisor.start_link(children, opts)
  end
  ```

  """

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
  @spec register(atom(), integer(), integer()) :: boolean()
  @doc """
  register a ratelimiter, save it in ets

  * `name` - server name
  * `rate` - how many milliseconds does it take to generate a token
  * `size` - maximum of the token pool

  ## Examples

  iex> Common.Ratelimit.register(:limiter, 1000, 10)
  true
  """
  def register(name, rate, size) do
    :ets.insert(:rate_pool, {name, rate, size})
  end

  @spec take_one(atom()) :: boolean()
  @doc """
  take a token from pool, if failed, means ratelimit is working

  * `name` - name of the server

  ## Examples

  iex> Common.Ratelimit.take_one(:limiter)
  true
  """
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
