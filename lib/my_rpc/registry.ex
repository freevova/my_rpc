defmodule MyRpc.Registry do
  @moduledoc """
  Local process storage for some instances.
  """

  @doc false
  def child_spec(_arg) do
    [keys: :duplicate, name: __MODULE__]
    |> Registry.child_spec()
    |> Supervisor.child_spec(id: __MODULE__)
  end
end
