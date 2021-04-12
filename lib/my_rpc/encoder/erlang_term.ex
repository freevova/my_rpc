defmodule MyRpc.Encoder.ErlangTerm do
  def encode(payload) do
    :erlang.term_to_binary(payload)
  end

  def decode(binary) do
    :erlang.binary_to_term(binary)
  end
end
