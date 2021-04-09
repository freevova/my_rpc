# MyRpc

This is simple implementation of RPC over RabbitMQ with headers exchange.
I was inspired by the [next](https://andrealeopardi.com/posts/rpc-over-rabbitmq-with-elixir/) article.

## Installation

Download and run RabbitMQ service with:
```
docker run -d --rm --hostname localhost --name rabbitmq -p 15672:15672 -p 5672:5672 rabbitmq:3-management
```
**Caller**

To start caller's service, run the following command:
```
iex -S mix
MyRpc.Application.start_caller()
```
This will run the suppervision tree for the caller with connection pools.
You can configure it with options list. Default options are:
```
opts = [
  host: "localhost",
  port: 5672,
  username: "guest",
  password: "guest",
  pools: 1,
  channels: 2,
  exchange: "rpc",
  response_queue: "caller.response_queue"
]
```
With default options, when starting the caller, it will create 1 pool of connections to the RabbitMQ with 2 channels.
The caller pushes all messages into one "rpc" excahnge and fetches the response from "caller.response_queue". Here we use `ROUTING POOL` to fetch the messages from the response queue instead of `CHECKOUT POOL`, so it don't block the chanel for other callers. This exchange uses headers exchange logic, so we pass receiver's service name and procedure into the message headers. Currently the call is stubed only for the fib function to the receiver service. It uses 1 parameter and encodes it as simple string because of `MyRpc.Encoder`. In general we can use here anything we want (erlang to binary, protobuf, json ...)
This is what happens, step by step, when a service makes an RPC:

* The caller assigns a new UUID to the request and encodes the request (`MyRpc.Encoder`).
* The caller includes the name of the response queue in the reply_to metadata field of the RabbitMQ message.
* The caller publishes the request on the main RPC exchange (rpc) using headers to specify the destination and procedure to call.
* If publishing the request is successful, the caller stores the request in an in-memory key-value store (ETS for Elixir and Erlang folks), storing the mapping from request ID to caller process. This is used to map responses back to requests when they come back.
* The caller has a pool of AMQP channels also consuming from the response queue. When the response comes back on such queue, a consumer channel picks it up, finds the corresponding caller process from the in-memory key-value store, and hands the caller process the response.

From a code standpoint, an RPC really does look like a function call:
```
MyRpc.PoolsSupervisor.call("calculator_svc", "fib", 3)
```

**Receiver**

Start receiver's service with
```
iex -S mix
MyRpc.Application.start_receiver()
```
Currently it is stub for `MyRpc.Services.Calculator`.
The receiver architecture, compared to the caller, is straightforward. Every service sets up a pool of RabbitMQ connections (and channels), declares a queue, and binds it to the main RPC exchange (rpc). That exchange is a headers exchange, and each service usually binds the queue with the destination header matching that service
We use Broadway to consume RPCs, hooking it up with the broadway_rabbitmq producer.
