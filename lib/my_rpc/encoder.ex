defmodule MyRpc.Encoder do
  @encoder MyRpc.Encoder.ErlangTerm

  defdelegate encode(data), to: @encoder
  defdelegate decode(data), to: @encoder
end
