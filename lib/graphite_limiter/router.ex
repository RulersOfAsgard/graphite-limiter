defmodule GraphiteLimiter.Router do
  @moduledoc """
  Module for validating metrics and sends or blocks them accordingly
  """
  alias GraphiteLimiter.Instrumenter

  @spec validate_metric({String.t, :valid | :not_valid}, integer) :: :ok
  def validate_metric({_metric, :not_valid}, _), do: Instrumenter.inc_metrics_dropped()
  def validate_metric({metric, :valid}, sender_pool_size) do
   GraphiteFetcher.get_paths(GraphiteFetcher)
   |> match_metric(metric)
   |> push_forward(sender_pool_size)
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
  defp push_forward({_metric, :block}, _pool), do: Instrumenter.inc_metrics_blocked()
  defp push_forward({metric, :ok}, pool) do
    Enum.random(1..pool)
    |> fn(nr) -> :"GraphiteSender#{nr}" end.()
    |> GenServer.cast({:send, metric})
  end
end
