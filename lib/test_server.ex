defmodule GraphiteTestServer do
  @moduledoc """
  Test server for handling connections initialized by GraphiteLimiter.
  Used in unit tests
  """
  require Logger

  def accept(port) do
    {:ok, socket} =
      :gen_tcp.listen(port, [:binary, packet: :line, active: false, reuseaddr: true])

    Logger.info("Starting TEST server. Accepting connections on port #{port}")
    loop_acceptor(socket)
  end

  defp loop_acceptor(socket) do
    {:ok, client} = :gen_tcp.accept(socket)
    {:ok, pid} =
      Task.Supervisor.start_child(DummyServer.TaskSupervisor, fn ->
        serve(client)
      end)
    :ok = :gen_tcp.controlling_process(client, pid)
    loop_acceptor(socket)
  end

  def serve(client) do
    case :gen_tcp.recv(client, 0) do
      {:ok, msg} ->
        Logger.info("Test Server received: #{msg}")
      {:error, :closed} -> exit(:shutdown)
    end

    serve(client)
  end
end
