defmodule GraphiteLimiter do
  @moduledoc """
  Documentation for GraphiteLimiter.
  """
  require Logger

  @behaviour GraphiteLimiter.Impl

  @parser Application.get_env(:graphite_limiter, :parser, GraphiteLimiter.DefaultImpl)

  @spec parse_metric(String.t, integer) :: :ok
  def parse_metric(metric, sender_pool_size) do
    @parser.parse_metric(metric, sender_pool_size)
  end
end
