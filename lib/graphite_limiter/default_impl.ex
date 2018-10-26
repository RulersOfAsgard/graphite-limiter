defmodule GraphiteLimiter.DefaultImpl do
  @moduledoc false
  alias GraphiteLimiter.Instrumenter
  @behaviour GraphiteLimiter.Impl

  @statsd_prefix Application.get_env(:graphite_limiter, :statsd_prefix, "aggregated")
  @statsd_prefix_length Application.get_env(:graphite_limiter, :statsd_prefix_length, 1)
  @path_depth Application.get_env(:graphite_limiter, :metrics_path_depth, 4)


  @spec parse_metric(String.t, integer) :: :ok
  def parse_metric(metric, sender_pool_size) do
    metric
    |> calculate_path_depth
    |> build_path
    |> increase_counter
    |> GraphiteLimiter.Router.validate_metric(sender_pool_size)
  end

  @spec increase_counter({String.t, String.t, :found | :not_found}) :: {String.t, :valid | :not_valid}
  defp increase_counter({metric, _path, :not_found}), do: {metric, :not_valid}
  defp increase_counter({metric, path, :found}) do
    Instrumenter.inc_metrics_by_path(path)
    {metric, :valid}
  end

  @spec calculate_path_depth(String.t) :: {String.t, integer}
  defp calculate_path_depth(metric) do
    path_depth = case String.starts_with?(metric, @statsd_prefix) do
      true ->  @path_depth + @statsd_prefix_length + 1
      false -> @path_depth
    end
    {metric, path_depth}
  end

  @spec build_path({String.t, [String.t]}) :: {String.t, String.t, :found | :not_found}
  defp build_path({metric, path_depth}) do
    {path, status} = metric
    |> String.split(" ")
    |> fn([name | _rest]) -> name end.()
    |> String.splitter(".")
    |> Enum.take(path_depth)
    |> path_extracted?(path_depth)
    |> join_parts
    {metric, path, status}
  end

  @spec path_extracted?(list(String.t), integer) :: {list(String.t), true | false}
  defp path_extracted?(metric_parts, path_depth) do
    {metric_parts, length(metric_parts) >= path_depth}
  end
  @spec join_parts({list(String.t), true | false}) :: {String.t, :found | :not_found}
  defp join_parts({metric_parts, true}), do: {Enum.join(metric_parts, "."), :found}
  defp join_parts({_metric_parts, false}), do: {"", :not_found}
end
