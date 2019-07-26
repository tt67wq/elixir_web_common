defmodule Common.RedisLock do
  @moduledoc """
  单机redis分布式锁
  """
  require Logger
  use Supervisor

  alias Common.Crypto

  @pool_size 2
  @release_script ~S"""
  if redis.call("get",KEYS[1]) == ARGV[1] then
    return redis.call("del", KEYS[1])
  else
    return 0
  end
  """

  #### redis part ####

  def start_link(args) do
    name = Keyword.get(args, :name, __MODULE__)
    Supervisor.start_link(__MODULE__, args, name: name)
  end

  @impl true
  def init(args) do
    Supervisor.init(get_workers(args), strategy: :one_for_one)
  end

  defp get_workers(args) do
    for i <- 0..(@pool_size - 1) do
      new_args = Keyword.update!(args, :name, fn x -> :"#{x}_#{i}" end)

      Supervisor.child_spec({Redix, new_args}, id: {RedisLock, Crypto.random_string(5)})
    end
  end

  defp command(name, command) do
    Redix.command(:"#{name}_#{random_index()}", command)
  end

  defp random_index do
    0..(@pool_size - 1)
    |> Enum.random()
  end

  #### lock part ####

  def helper_hash(), do: Crypto.sha(@release_script)

  def install_script(name) do
    case command(name, ["SCRIPT", "LOAD", @release_script]) do
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
  use a random string as value of resource
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
    case command(name, ["SET", resource, value, "NX", "PX", to_string(ttl)]) do
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

  @spec unlock(atom(), String.t(), String.t()) :: {:ok, integer()}
  def unlock(name, resource, value) do
    command(name, ["EVALSHA", helper_hash(), "1", resource, value])
  end
end
