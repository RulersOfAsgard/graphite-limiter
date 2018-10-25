defmodule GraphiteLimiter.DefaultImpl do
  @moduledoc false
  alias GraphiteLimiter.Instrumenter
  @behaviour GraphiteLimiter.Impl

  @statsd_prefix Application.get_env(:graphite_limiter, :statsd_prefix, "aggregated")
  @statsd_prefix_length Application.get_env(:graphite_limiter, :statsd_prefix, 1)
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

  @spec increase_counter({String.t, integer}) :: :ok
  defp increase_counter({path, path_length}) do
    if path_length >= @path_depth do
      Instrumenter.inc_metrics_by_path(path)
    end
  end

  @spec calculate_path_depth(String.t) :: integer
  defp calculate_path_depth(metric) do
    path_depth = case String.starts_with?(metric, @statsd_prefix) do
      true ->  @path_depth + @statsd_prefix_length + 1
      false -> @path_depth
    end
    {metric, path_depth}
  end

  @spec build_path({String.t, [String.t]}) :: {String.t, integer}
  defp build_path({metric, path_depth}) do
    metric
    |> String.split(" ")
    |> fn([name | _rest]) -> name end.()
    |> String.splitter(".")
    |> Enum.take(path_depth)
    |> actual_path_length
    |> join_parts
  end

  @spec actual_path_length(list(String.t)) :: {list(String.t), integer}
  defp actual_path_length(metric_parts), do: {metric_parts, length(metric_parts)}

  @spec join_parts({list(String.t), integer}) :: {String.t, integer}
  defp join_parts({metric_parts, nr_of_parts}), do: {Enum.join(metric_parts, "."), nr_of_parts}
end
