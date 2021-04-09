defmodule MyRpc.Encoder do
  def encode(args) do
    to_string(args)
  end

  def decode(args) do
    args
  end
end
