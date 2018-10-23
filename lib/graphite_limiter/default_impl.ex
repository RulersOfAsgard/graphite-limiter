defmodule GraphiteLimiter.DefaultImpl do
  @moduledoc false
  alias GraphiteLimiter.Instrumenter
  @behaviour GraphiteLimiter.Impl

  @statsd_prefix Application.get_env(:graphite_limiter, :statsd_prefix, "aggregated")
  @path_depth Application.get_env(:graphite_limiter, :metrics_path_depth, 4)


  @spec parse_metric(String.t, integer) :: :ok
  def parse_metric(metric, sender_pool_size) do
    metric
    |> calculate_path_depth
    |> build_path
    |> increase_counter

    GraphiteFetcher.get_paths(GraphiteFetcher)
    |> GraphiteLimiter.Router.validate_metric(metric, sender_pool_size)
  end

  @spec increase_counter(String.t) :: :ok
  defp increase_counter(path) do
    Instrumenter.inc_metrics_by_path(path)
  end

  @spec calculate_path_depth(String.t) :: integer
  defp calculate_path_depth(metric) do
    path_depth = case String.starts_with?(metric, @statsd_prefix) do
      true -> @statsd_prefix
              |> String.split(".")
              |> length
              |> fn(l) -> l + @path_depth + 1 end.()
      false -> @path_depth
    end
    {metric, path_depth}
  end

  @spec build_path({String.t, [String.t]}) :: String.t
  defp build_path({metric, path_depth}) do
    metric
    |> String.split(" ")
    |> fn([name | _rest]) -> name end.()
    |> String.split(".")
    |> Enum.take(path_depth)
    |> Enum.join(".")
  end
end
