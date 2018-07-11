defmodule GraphiteLimiter do
  @moduledoc """
  Documentation for GraphiteLimiter.
  """
  alias GraphiteLimiter.Instrumenter
  require Logger
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, %{socket: nil}, opts)
  end

  def init(_state) do
    Logger.info("starting Limiter server")
    socket = connect()
    {:ok, %{socket: socket}}
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

  def handle_info(:connect, state) do
    init(state)
    {:noreply, connect()}
  end

  def handle_info(:timeout, new_state) do
    Logger.warn("Timeout occured")
    new_state
  end

  def handle_call({:send_to_destination, metric}, _from, %{socket: socket} = state) do
    Logger.debug(fn -> "Sending metric `#{String.trim_trailing(metric, "\n")}`" end)
    case :gen_tcp.send(socket, metric) do
      :ok ->
        Instrumenter.inc_metrics_sent()
        Logger.debug(fn -> "#{String.trim_trailing(metric, "\n")} sent" end)
      err ->
        Instrumenter.inc_errors_sent(err)
        Logger.error(fn -> "#{inspect(err)}" end)
        # Raise error, to force reconnect
        raise("Failed to connect to remote graphite server")
    end
    {:reply, :ok, state}
  end

  def parse_metric(metric) do
    get_overloaded_paths()
    |> match_metric(metric)
    |> push_forward
  end

  defp get_overloaded_paths do
    Logger.debug("Fetching paths from cache")
    GenServer.call(GraphiteFetcher, :get_paths)
  end

  defp match_metric(paths, metric) do
    with true <- String.starts_with?(metric, paths) do
      {metric, :block}
    else
      false -> {metric, :ok}
    end
  end

  defp push_forward({metric, :block}) do
    Instrumenter.inc_metrics_blocked()
    Logger.warn("Metric `#{String.trim_trailing(metric, "\n")}` blocked")
  end
  defp push_forward({metric, :ok}) do
    GenServer.call(GraphiteLimiter, {:send_to_destination, metric})
  end
end
