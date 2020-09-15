defmodule Common.Ratelimit do
  @moduledoc """
  令牌桶限流器，基于Redis存储

  ## Config Example
  ```
  config :my_app, :ratelimit,
    name: :ratelimit,
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
  alias Common.TimeTool

  #### real part ####
  @spec take_one(atom(), String.t(), integer, integer) :: boolean()
  @doc """
  take a token from pool, if failed, means ratelimit is working

  * `server` - redis server process
  * `name`   - name of the limiter
  * `rate`   - how many milliseconds does it take to generate a token
  * `size`   - maximum of the token pool

  ## Examples

  iex> Common.Ratelimit.take_one(:ratelimit, :limiter, 1000, 200)
  true
  """
  def take_one(server, name, rate, size) do
    with ts <- TimeTool.timestamp(:milli_seconds),
         {:ok, lt} <- Redix.command(server, ["GET", "limiter:#{name}"]),
         lt <- fix_num(lt),
         counter <- div(ts - lt, rate) do
      cond do
        counter <= 0 ->
          false

        counter >= size ->
          Redix.command(server, ["SET", "limiter:#{name}", "#{ts - (size - 1) * rate}"])
          true

        :else ->
          Redix.command(server, ["SET", "limiter:#{name}", "#{lt + rate}"])
          true
      end
    end
  end

  defp fix_num(nil), do: 0
  defp fix_num(n), do: String.to_integer(n)
end
