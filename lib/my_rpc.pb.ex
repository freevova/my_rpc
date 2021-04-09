defmodule MyRpc.Reply do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          sum: integer
        }

  defstruct [:sum]

  field :sum, 1, type: :int32
end

defmodule MyRpc.AddRequest do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          n1: integer,
          n2: integer
        }

  defstruct [:n1, :n2]

  field :n1, 1, type: :int32
  field :n2, 2, type: :int32
end
