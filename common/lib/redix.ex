defmodule Common.Redix do
  @moduledoc """
  redis conn pool
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
  def command(name, command) do
    Redix.command(:"#{name}_#{random_index()}", command)
  end

  defp random_index do
    0..(@pool_size - 1)
    |> Enum.random()
  end
end
