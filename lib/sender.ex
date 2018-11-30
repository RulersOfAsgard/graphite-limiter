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
    |> Map.put(:send_buffer, Application.get_env(:graphite_limiter, :send_buffer))
    {:ok, new_state}
  end

  @spec connect :: port
  defp connect do
    opts = [:binary, packet: :line, active: false]
    addr =
      Application.get_env(:graphite_limiter, :graphite_dest_relay_addr, "localhost")
      |> String.to_charlist
    port = Application.get_env(:graphite_limiter, :graphite_dest_relay_port)
    Logger.debug(fn -> "connecting to: #{addr}:#{port}" end)
    case :gen_tcp.connect(addr, port, opts) do
      {:error, _msg} -> nil
      {:ok, socket} ->
        Logger.debug(fn -> "connected #{inspect(socket)}" end)
        socket
    end
  end

  @spec handle_info(:timeout, map) :: {:noreply, map}
  def handle_info(:timeout, state) do
    Logger.debug("TIMEOUT!!!!")
    {:noreply, state}
  end

  @spec handle_cast({:send, String.t}, map) :: {:noreply, map, non_neg_integer}
  def handle_cast({:send, message}, state) do
    {messages, queue_length} = {[message | state.messages], state.queue_length + 1}
    new_state =
      with true <- queue_length > state.send_buffer,
          :ok <- send_bulk(messages, state.socket)
      do
        Instrumenter.inc_metrics_sent(queue_length)
        %{state | queue_length: 0, messages: []}
      else
        :socket_err ->
          Logger.debug("Setting socket: nil")
          %{state | socket: nil}
        :error ->
          %{state | queue_length: queue_length, messages: messages, socket: connect()}
        _ -> %{state | queue_length: queue_length, messages: messages}
      end
    {:noreply, new_state, 4500}
  end

  @spec send_bulk(list(String.t), port() | nil)  :: :ok | :error | :socket_error
  defp send_bulk(messages, socket) when not is_nil(socket) do
    messages
    |> Enum.join("")
    |> send_message(socket)
  end
  defp send_bulk(_messages, nil), do: :error

  @spec send_message(String.t, port) :: :ok | :socket_err
  defp send_message(message, socket) do
    case :gen_tcp.send(socket, message) do
      :ok -> :ok
      {:error, err} ->
        Instrumenter.inc_errors_sent(err)
        Logger.error(fn -> "ERROR on sending event #{inspect(err)}" end)
        Port.close(socket)
        :socket_err
    end
  end

end
