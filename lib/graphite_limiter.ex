defmodule GraphiteLimiter do
  @moduledoc """
  Documentation for GraphiteLimiter.
  """
  alias GraphiteLimiter.Instrumenter
  require Logger
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, %{}, opts)
  end

  def init(state) do
    Logger.info("starting Limiter server")
    {:ok, state}
  end

  def handle_info(:timeout, new_state) do
    Logger.warn("Timeout occured")
    new_state
  end

  def handle_info({:timeout, new_state}) do
    Logger.warn("Timeout occured")
    new_state
  end

  def handle_cast({:send_to_destination, metric}, state) do
    GenServer.call(GraphiteSender, {:send, metric})
    {:noreply, state}
  end

  def parse_metric(metric) do
    get_overloaded_paths()
    |> match_metric(metric)
    |> push_forward
  end

  defp get_overloaded_paths do
    GraphiteFetcher.get_paths(GraphiteFetcher)
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
    GenServer.call(GraphiteSender, {:send, metric})
    # GenServer.cast(GraphiteLimiter, {:send_to_destination, metric})
    # :ok
  end
end
