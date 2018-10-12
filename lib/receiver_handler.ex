defmodule GraphiteReceiver.Handler do
  @moduledoc """
  A simple TCP protocol handler that echoes all messages received.
  """
  alias GraphiteLimiter.Instrumenter
  use GenServer
  require Logger

  # Client

  @doc """
  Starts the handler with `:proc_lib.spawn_link/3`.
  """
  def start_link(ref, socket, transport, _opts) do
    pid = :proc_lib.spawn_link(__MODULE__, :init_loop, [ref, socket, transport])
    {:ok, pid}
  end

  def init(args) do
      {:ok, args}
  end
  @doc """
  Initiates the handler, acknowledging the connection was accepted.
  Finally it makes the existing process into a `:gen_server` process and
  enters the `:gen_server` receive loop with `:gen_server.enter_loop/3`.
  """
  def init_loop(ref, socket, transport) do
    peername = stringify_peername(socket)

    Logger.debug(fn ->
      "Peer #{peername} connecting"
    end)

    :ok = :ranch.accept_ack(ref)
    :ok = transport.setopts(socket, [{:active, true}, {:packet, :line}, {:reuseaddr, false}])

    :gen_server.enter_loop(__MODULE__, [], %{
      socket: socket,
      transport: transport,
      peername: peername,
      sender_pool_size: Application.get_env(:graphite_limiter, :sender_pool, 1)
    })
  end

  # Server callbacks

  def handle_info({:tcp, _port, message},
                  %{peername: peer, sender_pool_size: pool_size} = state) do
    Logger.debug(fn ->
      "Received new message from peer #{peer}: #{inspect(message)}." end)
    Instrumenter.inc_metrics_received()
    GraphiteLimiter.parse_metric(message, pool_size)
    {:noreply, state}
  end

  def handle_info({:tcp_closed, _}, %{peername: peername} = state) do
    Instrumenter.inc_errors_received(:closed)
    Logger.debug(fn ->
      "Peer #{peername} disconnected"
    end)

    {:stop, :normal, state}
  end

  def handle_info({:tcp_error, _, reason}, %{peername: peername} = state) do
    Logger.info(fn ->
      "Error with peer #{peername}: #{inspect(reason)}"
    end)

    {:stop, :normal, state}
  end

  def handle_info({:error, reason}, %{peername: peername} = state) do
    Logger.info(fn ->
      "Error with peer #{peername}: #{inspect(reason)}"
    end)

    {:stop, :normal, state}
  end

  # Helpers

  defp stringify_peername(socket) do
    {:ok, {addr, port}} = :inet.peername(socket)

    address =
      addr
      |> :inet_parse.ntoa()
      |> to_string()

    "#{address}:#{port}"
  end
end
