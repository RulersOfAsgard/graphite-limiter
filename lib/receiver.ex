defmodule GraphiteReceiver do
  @moduledoc """
  Module for handling graphite requests
  """
  alias GraphiteLimiter.Instrumenter
  require Logger

  @doc """
  Starts accepting connections on the given `port`.
  """
  def accept(port) do
    {:ok, socket} =
      :gen_tcp.listen(port, [:binary, packet: :line, active: false, reuseaddr: true])

    Logger.info("Accepting connections on port #{port}")
    loop_acceptor(socket)
  end

  defp loop_acceptor(socket) do
    {:ok, client} = :gen_tcp.accept(socket)

    {:ok, pid} =
      Task.Supervisor.start_child(GraphiteReceiver.TaskSupervisor, fn ->
        serve(client)
      end)

    :gen_tcp.controlling_process(client, pid)
    # ^^ This makes the child process the “controlling process” of the client socket.
    # If we didn’t do this, the acceptor would bring down all the clients if it crashed
    # because sockets would be tied to the process that accepted them
    # (which is the default behaviour).
    loop_acceptor(socket)
  end

  defp serve(socket) do
    case read_line(socket) do
      {:ok, data} ->
        Instrumenter.inc_metrics_received()
        send_to_limiter(data)
      {:error, :closed} ->
        Instrumenter.inc_errors_received(:closed)
        exit(:shutdown)
      {:error, err} ->
        Instrumenter.inc_errors_received(err)
        Logger.error(fn -> "Error: #{inspect(err)}" end)
    end

    serve(socket)
  end

  defp read_line(socket) do
    :gen_tcp.recv(socket, 0)
  end

  defp send_to_limiter(data) do
    Logger.debug(fn -> "Receiving: #{String.trim_trailing(data, "\n")}" end)
    Task.Supervisor.start_child(GraphiteReceiver.TaskSupervisor, fn ->
      GraphiteLimiter.parse_metric(data)
    end)
  end
end
