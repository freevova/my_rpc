defmodule MyRpcTest do
  use ExUnit.Case
  doctest MyRpc

  test "greets the world" do
    assert MyRpc.hello() == :world
  end
end
