defmodule MyRpc.Config do
  @type channel_config() :: any()

  @type t() :: %__MODULE__{
          host: binary(),
          port: non_neg_integer(),
          username: binary(),
          password: binary(),
          pools: non_neg_integer(),
          channels: non_neg_integer(),
          exchange: binary(),
          response_queue: binary()
        }

  defstruct host: "localhost",
            port: 5672,
            username: "guest",
            password: "guest",
            pools: 1,
            channels: 2,
            exchange: "rpc",
            response_queue: "caller.response_queue"

  def new(opts \\ %{}) do
    struct!(__MODULE__, opts)
  end

  @connection_opts [:host, :port, :username, :password]
  def connection_opts(config) do
    config
    |> Map.take(@connection_opts)
    |> Enum.into([])
  end
end
