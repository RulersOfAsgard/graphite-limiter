defmodule GraphiteLimiter do
  @moduledoc """
  Documentation for GraphiteLimiter.
  """
  alias GraphiteLimiter.Instrumenter
  require Logger

  @spec parse_metric(String.t, integer) :: :ok
  def parse_metric(metric, sender_pool_size) do
    get_overloaded_paths()
    |> match_metric(metric)
    |> push_forward(sender_pool_size)
  end

  @spec get_overloaded_paths() :: list(String.t)
  defp get_overloaded_paths do
    GraphiteFetcher.get_paths(GraphiteFetcher)
  end

  @spec match_metric(list(String.t), String.t) :: {String.t, :ok | :block}
  defp match_metric(paths, metric) do
    with true <- String.starts_with?(metric, paths) do
      {metric, :block}
    else
      false -> {metric, :ok}
    end
  end

  @spec push_forward({String.t, :ok | :block}, integer) :: :ok
  defp push_forward({metric, :block}, _pool) do
    Instrumenter.inc_metrics_blocked()
    Logger.warn("Metric `#{String.trim_trailing(metric, "\n")}` blocked")
  end
  defp push_forward({metric, :ok}, pool) do
    Enum.random(1..pool)
    |> fn(nr) -> :"GraphiteSender#{nr}" end.()
    |> GenServer.cast({:send, metric})

  end
end
