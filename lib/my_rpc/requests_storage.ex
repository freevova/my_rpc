defmodule MyRpc.RequestStorage do
  use GenServer

  @moduledoc """
  KeyValue storage for RPC callers in format {request_id, caller}
  """

  @doc false
  def start_link(opts), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

  @doc false
  def get(key), do: GenServer.call(__MODULE__, {:get, key})

  @doc false
  def put(data), do: GenServer.call(__MODULE__, {:put, data})

  @impl true
  def init(_opts) do
    {:ok, :ets.new(:requests_storage, [:set, :public])}
  end

  @impl true
  def handle_call({:get, key}, _from, pid) do
    [{_, value}] = :ets.lookup(pid, key)
    {:reply, value, pid}
  end

  @impl true
  def handle_call({:put, data}, _from, pid) do
    result = :ets.insert(pid, data)

    {:reply, result, pid}
  end
end
