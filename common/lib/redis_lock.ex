defmodule Common.RedisLock do
  @moduledoc """
  单机redis分布式锁
  ## Config example
  ```
  config :my_app, :rds_lock,
    name: :lock,
    host: "localhost",
    port: 6379
  ```

  ## Usage:
  ```
  def start(_type, _args) do
    # List all child processes to be supervised
    children = [
      {RedisLock, Application.get_env(:my_app, :rds_lock)},
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: MyApp.Supervisor]
    Supervisor.start_link(children, opts)
  end

  """
  require Logger
  alias Common.Crypto

  @release_script ~S"""
  if redis.call("get",KEYS[1]) == ARGV[1] then
    return redis.call("del", KEYS[1])
  else
    return 0
  end
  """

  #### lock part ####

  defp helper_hash(), do: Crypto.sha(@release_script) |> Base.encode16(case: :lower)

  defp install_script(name) do
    case Redix.command(name, ["SCRIPT", "LOAD", @release_script]) do
      {:ok, val} ->
        Logger.info(val)

        if val == helper_hash() do
          {:ok, val}
        else
          {:error, :hash_mismatch}
        end

      other ->
        other
    end
  end

  @doc """
  lock a lock on a resource last for ttl millseconds, this function
  returns a random string as the secret to unlock

  * `name`     - name of genserver
  * `resource` - name of a resource
  * `ttl`      - after how many millseconds to free this lock

  ## Examples

  iex> Common.RedisLock.lock(:lock, "foo", 1000)
  {:ok, "r9j_XinmrB"}
  """
  @spec lock(atom(), String.t(), integer()) :: {:ok, String.t()} | {:error, any()}
  def lock(name, resource, ttl) do
    value = Crypto.random_string(10)

    case lock(name, resource, value, ttl) do
      :ok -> {:ok, value}
      {:error, err} -> {:error, err}
    end
  end

  defp lock(name, resource, value, ttl) do
    case Redix.command(name, ["SET", resource, value, "NX", "PX", to_string(ttl)]) do
      {:ok, "OK"} ->
        :ok

      {:ok, nil} ->
        Logger.info("<RedisLock> resource: #{resource} is already locked")
        {:error, :already_locked}

      other ->
        Logger.error("<RedisLock> failed to execute redis SET: #{inspect(other)}")
        {:error, :system_error}
    end
  end

  @doc """
  free a lock by secret

  * `name` - name of genserver
  * `resource` - name of resource
  * `secret` - value returned by lock function

  ## Examples

  iex> Common.RedisLock.unlock(:lock, "foo", "JFaguzdH1Y")
  {:ok, 1}
  """
  @spec unlock(atom(), String.t(), String.t()) :: {:ok, integer()}
  def unlock(name, resource, secret) do
    Redix.command(name, ["EVALSHA", helper_hash(), "1", resource, secret])
  end
end
