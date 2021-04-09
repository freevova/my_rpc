defmodule MyRpc.PoolsSupervisor do
  use Supervisor

  def start_link(config) do
    Supervisor.start_link(__MODULE__, config, name: __MODULE__)
  end

  @impl true
  def init(config) do
    children = [
      MyRpc.RequestStorage,
      MyRpc.Registry,
      {MyRpc.PoolSupervisor, config}
    ]

    Supervisor.init(children, strategy: :rest_for_one)
  end

  @available_receivers ["calculator_svc"]
  def call(service_name, procedure_name, args) do
    if Enum.member?(@available_receivers, service_name) do
      channels = Registry.lookup(MyRpc.Registry, :channels)

      # TODO: think of Round-robin routing
      {pid, _value = nil} = Enum.random(channels)
      MyRpc.Channel.request(pid, service_name, procedure_name, args)
    else
      {:error, :unknown_service_name}
    end
  end

  def test do
    MyRpc.PoolsSupervisor.call("calculator_svc", "fib", 3)
  end
end
