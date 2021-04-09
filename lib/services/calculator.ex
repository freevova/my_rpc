defmodule MyRpc.Services.Calculator do
  defdelegate add(a, b), to: Kernel, as: :+
  defdelegate sub(a, b), to: Kernel, as: :-

  def fib(0), do: 0
  def fib(1), do: 1
  def fib(n) when n > 1, do: fib(n - 1) + fib(n - 2)
end
