defmodule GraphiteSender do
  @moduledoc """
  Module for sending requests to destination relays
  """
  alias GraphiteLimiter.Instrumenter
  require Logger
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, %{}, opts)
  end

  def init(state) do
    new_state = state
    |> Map.put(:queue_length, 0)
    |> Map.put(:messages, [])
    |> Map.put(:socket, connect())
    {:ok, new_state}
  end

  defp connect do
    opts = [:binary, packet: :line, active: false]
    addr =
      Application.get_env(:graphite_limiter, :graphite_dest_relay_addr, "localhost")
      |> String.to_charlist
    port = Application.get_env(:graphite_limiter, :graphite_dest_relay_port)
    Logger.debug(fn -> "connecting to: #{addr}:#{port}" end)
    case :gen_tcp.connect(addr, port, opts) do
      {:error, _msg} ->
        Process.sleep(1000)
        connect()
      {:ok, socket} -> socket
    end
  end

  def handle_call({:send, message}, _from, state) do
    {messages, queue_length} = {[message | state.messages], state.queue_length + 1}
    new_state =
      with true <- queue_length > Application.get_env(:graphite_limiter, :send_buffer),
          :ok <- send_bulk(messages, state.socket)
      do
        Instrumenter.inc_metrics_sent(queue_length)
        %{state | queue_length: 0, messages: []}
      else
        _ -> %{state | queue_length: queue_length, messages: messages}
      end
    {:reply, :ok, new_state}
  end

  @spec send_bulk(list(String.t), pid())  :: :ok | :error
  defp send_bulk(messages, socket) do
    messages
    |> Enum.join("")
    |> send_message(socket)
  end

  defp send_message(message, socket) do
    case :gen_tcp.send(socket, message) do
      :ok -> :ok
      err ->
        Instrumenter.inc_errors_sent(err)
        Logger.error(fn -> "#{inspect(err)}" end)
        # Raise error, to force reconnect
        raise("Failed to connect to remote graphite server")
    end
  end

end
