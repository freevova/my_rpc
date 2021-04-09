defmodule MyRpc.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = []
    opts = [strategy: :rest_for_one, name: MyRpc.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def start_caller(opts \\ []) do
    configs = MyRpc.Config.new(opts)
    Supervisor.start_child(MyRpc.Supervisor, {MyRpc.PoolsSupervisor, configs})
  end

  def start_receiver(_opts \\ []) do
    broadway_options = [
      queue: "calculator_svc.rpcs",
      on_failure: :reject_and_requeue,
      declare: [exclusive: true],
      bindings: [{"rpc", arguments: [{"destination", "calculator_svc"}]}],
      metadata: [:reply_to, :correlation_id]
    ]

    Supervisor.start_child(MyRpc.Supervisor, {MyRpc.Receiver, broadway_options})
  end
end
