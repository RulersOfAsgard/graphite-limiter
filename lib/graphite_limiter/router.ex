defmodule GraphiteLimiter.Router do
  @moduledoc """
  Module for validating metrics and sends or blocks them accordingly
  """
  alias GraphiteLimiter.Instrumenter

  def validate_metric(paths, metric, sender_pool_size) do
    paths
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
  defp push_forward({_metric, :block}, _pool) do
    Instrumenter.inc_metrics_blocked()
  end
  defp push_forward({metric, :ok}, pool) do
    Enum.random(1..pool)
    |> fn(nr) -> :"GraphiteSender#{nr}" end.()
    |> GenServer.cast({:send, metric})

  end
end
