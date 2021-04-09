defmodule MyRpc.Receiver do
  use Broadway

  @type message :: %Broadway.Message{
          acknowledger:
            {BroadwayRabbitMQ.Producer,
             %AMQP.Channel{
               conn: %AMQP.Connection{pid: pid()},
               custom_consumer: {AMQP.SelectiveConsumer, pid()},
               pid: pid()
             },
             %{
               client: BroadwayRabbitMQ.AmqpClient,
               delivery_tag: non_neg_integer(),
               on_failure: atom(),
               on_success: atom(),
               redelivered: boolean()
             }},
          batch_key: atom(),
          batch_mode: atom(),
          batcher: atom(),
          data: any(),
          metadata: %{
            amqp_channel: %AMQP.Channel{
              conn: %AMQP.Connection{pid: pid()},
              custom_consumer: {AMQP.SelectiveConsumer, pid()},
              pid: pid()
            },
            correlation_id: binary(),
            reply_to: binary()
          },
          status: :ok | {:error, any()}
        }
  @type opts :: [
          queue: binary(),
          on_failure: atom(),
          declare: [exclusive: boolean()],
          bindings: [{binary(), arguments: [{binary(), binary()}]}]
          # metadata: [:reply_to, :correlation_id]
        ]

  def start_link(opts) do
    Broadway.start_link(__MODULE__,
      name: __MODULE__,
      producer: [module: {BroadwayRabbitMQ.Producer, opts}],
      processors: [default: [concurrency: 10]]
    )
  end

  defp decode_request!(data) do
    {n, _} = Integer.parse(data)
    n
  end

  defp process_request(data) do
    MyRpc.Services.Calculator.fib(data)
  end

  defp encode_response!(data) do
    to_string(data)
  end

  def handle_message(_, %Broadway.Message{} = message, _context) do
    IO.inspect(message)
    # AMQP.Basic.ack(message.metadata.amqp_channel, meta.delivery_tag)

    response =
      message.data
      |> decode_request!()
      |> process_request()
      |> encode_response!()

    AMQP.Basic.publish(
      message.metadata.amqp_channel,
      "",
      message.metadata.reply_to,
      response,
      correlation_id: message.metadata.correlation_id
    )

    message
  end
end
