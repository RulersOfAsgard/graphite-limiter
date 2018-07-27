defmodule GraphiteReceiver do
  @moduledoc """
  Module for handling graphite requests
  """
  alias GraphiteLimiter.Instrumenter
  require Logger

  @delay Application.get_env(:graphite_limiter, :listen_retry_delay, 1000)

  @doc """
  Starts accepting connections on the given `port`.
  """
  @spec accept(non_neg_integer) :: no_return
  def accept(port) do
    with {:ok, socket} <- :gen_tcp.listen(
      port, [:binary, packet: :line, active: false]) do
          Logger.info("Accepting connections on port #{port}")
          # we have to get `sender_pool` env here, as keeping for example it in GraphiteLimiter
          # gen server state and fetching in while parsing a metric slows down whole process.
          # Passing it as an arg in function, improves performance significanlty
          sender_pool_size = Application.get_env(:graphite_limiter, :sender_pool, 1)
          loop_acceptor(socket, sender_pool_size)
    else
      {:error, err} ->
        Logger.warn("Failed to start receiver server: #{err}")
        Process.sleep(@delay)
        accept(port)
    end
  end

  @spec loop_acceptor(port, integer) :: no_return
  defp loop_acceptor(socket, sender_pool_size) do
    {:ok, client} = :gen_tcp.accept(socket)
    {:ok, pid} =
      Task.Supervisor.start_child(GraphiteReceiver.TaskSupervisor, fn ->
        serve(client, sender_pool_size)
      end)
    :gen_tcp.controlling_process(client, pid)
    # ^^ This makes the child process the “controlling process” of the client socket.
    # If we didn’t do this, the acceptor would bring down all the clients if it crashed
    # because sockets would be tied to the process that accepted them
    # (which is the default behaviour).
    loop_acceptor(socket, sender_pool_size)
  end

  @spec serve(port, integer) :: no_return
  defp serve(client, sender_pool_size) do
    case read_line(client) do
      {:ok, data} ->
        Instrumenter.inc_metrics_received()
        send_to_limiter(data, sender_pool_size)
        serve(client, sender_pool_size)
      {:error, err} ->
        Instrumenter.inc_errors_received(err)
        Logger.debug(fn -> "Client error: #{inspect(err)}" end)
        Port.close(client)
    end

  end

  @spec read_line(port) :: {:ok, String.t} | {:error, :closed | :inet.posix}
  defp read_line(client_socket) do
    :gen_tcp.recv(client_socket, 0)
  end

  @spec send_to_limiter(String.t, integer) :: :ok
  defp send_to_limiter(data, sender_pool_size) do
    GraphiteLimiter.parse_metric(data, sender_pool_size)
  end
end
