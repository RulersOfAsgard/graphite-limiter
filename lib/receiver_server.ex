defmodule GraphiteReceiver do
  @moduledoc """
  A simple TCP server.
  """

  use GenServer

  alias GraphiteReceiver.Handler

  require Logger

  @doc """
  Starts the server.
  """
  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  @doc """
  Initiates the listener (pool of acceptors).
  """
  def init(port: port) do
    opts = [{:port, port}, {:max_connections, 3000}]

    {:ok, pid} = :ranch.start_listener(:receiver_server, :ranch_tcp, opts, Handler, [])

    Logger.info(fn ->
      "Listening for connections on port #{port}"
    end)

    {:ok, pid}
  end
end
