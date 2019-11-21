defmodule Common.Cache do
  @moduledoc """
  简单缓存
  """
  @callback put(atom(), String.t(), String.t(), integer()) :: {:ok, any()}
  @callback get(atom(), String.t()) :: {:ok, String.t()}
  @callback exist?(atom(), String.t()) :: boolean()
  @callback del(atom(), String.t()) :: {:ok, any()}
end

defmodule Common.RedisCache do
  @moduledoc """
  redis cache

  ## Config example
  ```
  config :my_app, :cache,
    name: :cache,
    host: "localhost",
    port: 6379
  ```

  ## Usage:
  ```
  def start(_type, _args) do
    # List all child processes to be supervised
    children = [
      {RedisCache, Application.get_env(:my_app, :cache)},
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: MyApp.Supervisor]
    Supervisor.start_link(children, opts)
  end
  ```

  """

  @behaviour Common.Cache

  def start_link(args) do
    Redix.start_link(args)
  end

  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]},
      type: :worker,
      restart: :permanent,
      shutdown: 500
    }
  end

  #### cache part ####

  @impl Common.Cache
  @doc """
  add a new cache key/value

  * `name` - cache service name, genserver name
  * `key`  - key of cache
  * `value` - value of cache
  * `expire` - how many seconds this cache pair can survive 

  ## Examples

  iex> Common.RedisCache.put(:cache, "foo", "bar", 5)
  {:ok, "OK"}
  """
  def put(name, key, value, expire) do
    Redix.command(name, ["SETEX", key, expire, value])
  end

  @impl Common.Cache
  @doc """
  get cache value by key

  * `name` - cache service name, genserver name
  * `key` - key of cache

  ## Examples

  iex> Common.RedisCache.get(:cache, "foo")
  {:ok, "bar"}
  """
  def get(name, key) do
    Redix.command(name, ["GET", key])
  end

  def get!(name, key) do
    case get(name, key) do
      {:ok, value} -> value
      _ -> nil
    end
  end

  @impl Common.Cache
  @doc """
  check if key in cache table

  * `name` - cache service name, genserver name
  * `key` - key of cache

  ## Examples

  iex> Common.RedisCache.exists?(:cache, "foo")
  false
  """
  def exist?(name, key) do
    case Redix.command(name, ["GET", key]) do
      {:ok, nil} -> false
      _ -> true
    end
  end

  @impl Common.Cache
  @doc """
  drop a cache pair

  * `name` - cache service name, genserver name
  * `key` - key of cache

  ## Examples

  iex> Common.RedisCache.del(:cache, "foo")
  {:ok, 1}
  """
  def del(name, key) do
    Redix.command(name, ["DEL", key])
  end
end

defmodule Common.EtsCache do
  @moduledoc """
  本地ETS缓存，用于要求不高的场景，
  进程中断则所有的缓存丢失，如果想做持久化需要自己再做二次开发


  ## Config example
  ```
  config :my_app, :cache,
    name: :cache
  ```

  ## Usage:
  ```
  def start(_type, _args) do
    # List all child processes to be supervised
    children = [
      {EtsCache, Application.get_env(:my_app, :cache)},
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: MyApp.Supervisor]
    Supervisor.start_link(children, opts)
  end
  ```

  """
  use GenServer

  @behaviour Common.Cache
  @table_name :ets_cache
  @beat_delta 500

  alias Common.TimeTool

  def start_link(args) do
    name = Keyword.get(args, :name, __MODULE__)
    GenServer.start_link(__MODULE__, args, name: name)
  end

  @impl Common.Cache
  @doc """
  add a new cache key/value

  * `name` - cache service name, genserver name
  * `key`  - key of cache
  * `value` - value of cache
  * `expire` - how many seconds this cache pair can survive 

  ## Examples

  iex> Common.EtsCache.put(:cache, "foo", "bar", 5)
  {:ok, "OK"}
  """
  def put(name, key, value, expire) do
    {:ok, :ets.insert(name, {key, value, TimeTool.timestamp(:seconds) + expire})}
  end

  @impl Common.Cache
  @doc """
  get cache value by key

  * `name` - cache service name, genserver name
  * `key` - key of cache

  ## Examples

  iex> Common.EtsCache.get(:cache, "foo")
  {:ok, "bar"}
  """
  def get(name, key) do
    case :ets.lookup(name, key) do
      [] -> {:ok, nil}
      [{_, value, _}] -> {:ok, value}
    end
  end

  @impl Common.Cache
  @doc """
  check if key in cache table

  * `name` - cache service name, genserver name
  * `key` - key of cache

  ## Examples

  iex> Common.EtsCache.exists?(:cache, "foo")
  false
  """
  def exist?(name, key) do
    {:ok, nil} != get(name, key)
  end

  @impl Common.Cache
  @doc """
  drop a cache pair

  * `name` - cache service name, genserver name
  * `key` - key of cache

  ## Examples

  iex> Common.EtsCache.del(:cache, "foo")
  {:ok, 1}
  """
  def del(name, key) do
    {:ok, :ets.delete(name, key)}
  end

  #### Server
  @impl true
  def init(args) do
    table_name = Keyword.get(args, :name, @table_name)

    :ets.new(table_name, [
      :set,
      :named_table,
      :public,
      read_concurrency: true,
      write_concurrency: true
    ])

    schedule_work(@beat_delta)
    {:ok, %{name: table_name}}
  end

  @impl true
  @doc """
  auto drop the key/value if the timestamp matches
  """
  def handle_info(:work, state) do
    now = TimeTool.timestamp(:seconds)

    state.name
    |> :ets.select([{{:"$1", :_, :"$2"}, [{:<, :"$2", now}], [:"$1"]}])
    |> Enum.map(fn x -> :ets.delete(state.name, x) end)

    schedule_work(@beat_delta)
    {:noreply, state}
  end

  defp schedule_work(time_delta), do: Process.send_after(self(), :work, time_delta)
end
