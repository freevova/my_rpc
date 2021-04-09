defmodule MyRpc.ConnectionSupervisor do
  use Supervisor

  def start_link(config) do
    Supervisor.start_link(__MODULE__, config)
  end

  @impl true
  def init(config) do
    children = [{MyRpc.Connection, {self(), config}}]

    Supervisor.init(children, strategy: :one_for_all)
  end
end
