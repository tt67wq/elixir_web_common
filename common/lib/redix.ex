defmodule Common.Redix do
  @moduledoc """
  redis conn pool

  ## Config example
  ```
  config :my_app, :redis,
    name: :rds,
    host: "localhost",
    port: 6379
  ```

  ## Usage

  ```
  def start(_type, _args) do
    # List all child processes to be supervised
    children = [
      {Redix, Application.get_env(:my_app, :redis)},
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: MyApp.Supervisor]
    Supervisor.start_link(children, opts)
  end

  ```

  ## Example
  iex(1)> Common.Redix.command(:rds, ["GET", "foo"])     
  {:ok, nil}
  iex(2)> Common.Redix.command(:rds, ["SET", "foo", "bar"])
  {:ok, "OK"}
  iex(3)> Common.Redix.command(:rds, ["GET", "foo"])       
  {:ok, "bar"}

  """
  use Supervisor
  alias Common.Crypto
  @pool_size 5

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

      Supervisor.child_spec({Redix, new_args}, id: {Redis, Crypto.random_string(5)})
    end
  end

  @spec command(atom(), list(String.t())) :: {:ok, any()}
  @doc """
  send command to redis client

  * `name` - name of genserver
  * `command` - a list of redis instruction

  ## Examples

  iex(1)> Common.Redix.command(:rds, ["GET", "foo"])     
  {:ok, nil}
  iex(2)> Common.Redix.command(:rds, ["SET", "foo", "bar"])
  {:ok, "OK"}
  iex(3)> Common.Redix.command(:rds, ["GET", "foo"])       
  {:ok, "bar"}
  """
  def command(name, command) do
    Redix.command(:"#{name}_#{random_index()}", command)
  end

  defp random_index do
    0..(@pool_size - 1)
    |> Enum.random()
  end
end
