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
  use Supervisor
  alias Common.Crypto
  @behaviour Common.Cache
  @pool_size 5

  #### redis part ####

  def start_link(args) do
    name = Keyword.get(args, :name, __MODULE__)
    Supervisor.start_link(__MODULE__, args, name: name)
  end

  ##### callback
  @impl true
  def init(args) do
    Supervisor.init(get_workers(args), strategy: :one_for_one)
  end

  defp get_workers(args) do
    for i <- 0..(@pool_size - 1) do
      args = Keyword.update!(args, :name, fn x -> :"#{x}_#{i}" end)
      Supervisor.child_spec({Redix, args}, id: {RedisCache, Crypto.random_string(5)})
    end
  end

  defp command(name, command) do
    Redix.command(:"#{name}_#{random_index()}", command)
  end

  defp random_index do
    0..(@pool_size - 1)
    |> Enum.random()
  end

  #### cache part ####

  @impl Common.Cache
  def put(name, key, value, expire) do
    command(name, ["SETEX", key, expire, value])
  end

  @impl Common.Cache
  def get(name, key) do
    command(name, ["GET", key])
  end

  def get!(name, key) do
    case get(name, key) do
      {:ok, value} -> value
      _ -> nil
    end
  end

  @impl Common.Cache
  def exist?(name, key) do
    case command(name, ["GET", key]) do
      {:ok, nil} -> false
      _ -> true
    end
  end

  @impl Common.Cache
  def del(name, key) do
    command(name, ["DEL", key])
  end
end

defmodule Common.EtsCache do
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
  def put(name, key, value, expire) do
    {:ok, :ets.insert(name, {key, value, TimeTool.timestamp(:seconds) + expire})}
  end

  @impl Common.Cache
  def get(name, key) do
    case :ets.lookup(name, key) do
      [] -> {:ok, nil}
      [{_, value, _}] -> {:ok, value}
    end
  end

  @impl Common.Cache
  def exist?(name, key) do
    {:ok, nil} != get(name, key)
  end

  @impl Common.Cache
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
  def handle_info(:work, state) do
    now = TimeTool.timestamp(:seconds)
    :ets.match_delete(state.name, {:_, :_, now})
    schedule_work(@beat_delta)
    {:noreply, state}
  end

  defp schedule_work(time_delta), do: Process.send_after(self(), :work, time_delta)
end
