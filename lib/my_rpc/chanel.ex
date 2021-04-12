defmodule MyRpc.Channel do
  use GenServer
  require Logger

  defmodule State do
    @enforce_keys [:connection, :channel, :config, :consumer_tag]
    @type t :: %__MODULE__{
            channel: AMQP.Channel.t(),
            connection: AMQP.Connection.t(),
            consumer_tag: binary(),
            config: MyRpc.Config.t()
          }
    defstruct @enforce_keys
  end

  def start_link(connection, config) do
    GenServer.start_link(__MODULE__, {connection, config})
  end

  @spec request(pid(), binary(), binary(), any()) :: term()
  def request(pid, service_name, procedure_name, args) do
    GenServer.call(pid, {:request, {service_name, procedure_name, args}})
  end

  @impl true
  def init({connection, config}) do
    state = %State{connection: connection, config: config, channel: nil, consumer_tag: nil}
    {:ok, state, {:continue, :connect}}
  end

  @impl true
  def handle_continue(:connect, %State{connection: connection, config: config} = state) do
    with {:ok, channel} <- AMQP.Channel.open(connection) do
      exchange = Map.fetch!(config, :exchange)
      response_queue = Map.fetch!(config, :response_queue)

      Registry.register(MyRpc.Registry, :channels, _value = nil)
      :ok = AMQP.Exchange.declare(channel, exchange, :headers)
      AMQP.Queue.declare(channel, response_queue, auto_delete: true)
      {:ok, consumer_tag} = AMQP.Basic.consume(channel, response_queue)

      {:noreply, %{state | channel: channel, consumer_tag: consumer_tag}}
    end
  end

  @impl true
  def handle_call({:request, {m, f, a}}, from, %State{channel: channel, config: config} = state) do
    correlation_id = generate_correlation_id()
    MyRpc.RequestStorage.put({correlation_id, from})
    data = MyRpc.Encoder.encode({f, a})

    opts = [
      reply_to: config.response_queue,
      correlation_id: correlation_id,
      headers: [{"destination", m}, {"procedure", f}]
    ]

    AMQP.Basic.publish(channel, config.exchange, "", data, opts)

    {:noreply, state}
  end

  @impl true
  def handle_info(
        {:basic_consume_ok, %{consumer_tag: consumer_tag}},
        %State{consumer_tag: consumer_tag} = state
      ) do
    {:noreply, state}
  end

  def handle_info({:basic_deliver, payload, meta}, %State{channel: channel} = state) do
    data = MyRpc.Encoder.decode(payload)
    from = MyRpc.RequestStorage.get(meta.correlation_id)

    AMQP.Basic.ack(channel, meta.delivery_tag)
    GenServer.reply(from, {:ok, data})

    {:noreply, state}
  end

  def handle_info(data, state) do
    {:stop, {:shutdown, data}, state}
  end

  @impl true
  def terminate(reason, _state) do
    Logger.error("[Rabbit] terminating a channel with the reason: #{inspect(reason)}")
    Registry.unregister(MyRpc.Registry, :channels)
  end

  defp generate_correlation_id do
    :erlang.unique_integer() |> :erlang.integer_to_binary() |> Base.encode64()
  end

  def child_spec({connection, config}) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [connection, config]}
    }
  end
end
