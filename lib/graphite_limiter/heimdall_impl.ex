defmodule GraphiteLimiter.HeimdallImpl do
  @moduledoc """
  Documentation for GraphiteLimiter.
  """
  require Logger

  @behaviour GraphiteLimiter.Impl

  @spec parse_metric(String.t, integer) :: :ok
  def parse_metric(metric, sender_pool_size) do
    get_overloaded_paths()
    |> GraphiteLimiter.Router.validate_metric(metric, sender_pool_size)
  end

  @spec get_overloaded_paths() :: list(String.t)
  defp get_overloaded_paths do
    GraphiteFetcher.get_paths(GraphiteFetcher)
  end
end
