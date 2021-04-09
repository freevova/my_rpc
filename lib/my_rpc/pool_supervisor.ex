defmodule MyRpc.PoolSupervisor do
  use Supervisor

  def start_link(config) do
    Supervisor.start_link(__MODULE__, config)
  end

  @impl true
  def init(config) do
    children =
      for index <- 1..config.pools do
        Supervisor.child_spec({MyRpc.ConnectionSupervisor, config},
          id: {MyRpc.ConnectionSupervisor, index}
        )
      end

    Supervisor.init(children, strategy: :one_for_one)
  end
end
