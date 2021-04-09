defmodule MyRpc.Connection do
  use GenServer
  require Logger

  defmodule State do
    @enforce_keys [:config]
    @type t :: %__MODULE__{
            supervisor: pid(),
            connection: AMQP.Connection.t(),
            config: MyRpc.Config.t()
          }
    defstruct supervisor: nil, connection: nil, config: nil
  end

  @spec start_link(pid(), MyRpc.Config.t()) :: GenServer.on_start()
  def start_link(sup, config) do
    GenServer.start_link(__MODULE__, {sup, config})
  end

  @impl true
  def init({supervisor, config}) do
    {:ok, %State{supervisor: supervisor, config: config}, {:continue, :connect}}
  end

  @impl true
  def handle_continue(:connect, %State{supervisor: supervisor, config: config} = state) do
    with {:ok, connection} <-
           config
           |> MyRpc.Config.connection_opts()
           |> AMQP.Connection.open() do
      Logger.debug("[Rabbit] connected")
      true = Process.link(connection.pid)

      connections_specs =
        for index <- 1..config.channels do
          Supervisor.child_spec({MyRpc.Channel, {connection, config}}, id: {MyRpc.Channel, index})
        end

      connections_supervisor_spec = %{
        id: MyRpc.ChannelsSupervisor,
        type: :supervisor,
        restart: :temporary,
        start: {Supervisor, :start_link, [connections_specs, [strategy: :one_for_one]]}
      }

      {:ok, _} = Supervisor.start_child(supervisor, connections_supervisor_spec)

      {:noreply, %{state | connection: connection}}
    else
      {:error, reason} ->
        Logger.error("[Rabbit] error opening a connection reason: #{inspect(reason)}")
        {:stop, reason, %State{config: config}}
    end
  end

  @impl true
  def terminate(_reason, %{connection: connection}) do
    if connection && Process.alive?(connection.pid) do
      AMQP.Connection.close(connection)
    end
  end

  def child_spec({sup, config}) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [sup, config]}
    }
  end
end
