defmodule MyRpc.MixProject do
  use Mix.Project

  def project do
    [
      app: :my_rpc,
      version: "0.1.0",
      elixir: "~> 1.11",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:lager, :logger, :amqp],
      mod: {MyRpc.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:amqp, "~> 2.0", override: true},
      {:grpc, github: "elixir-grpc/grpc"},
      {:cowlib, "~> 2.9.0", override: true},
      {:broadway, "~> 0.6.0"},
      {:broadway_rabbitmq, "~> 0.6.5"}
    ]
  end
end
