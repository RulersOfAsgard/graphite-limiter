defmodule GraphiteLimiter do
  @moduledoc """
  Documentation for GraphiteLimiter.
  """
  require Logger

  @behaviour GraphiteLimiter.Impl

  @parser Application.get_env(:graphite_limiter, :parser, GraphiteLimiter.DefaultImpl)

  @spec parse_metric(String.t, map) :: :ok
  def parse_metric(metric, opts) do
    @parser.parse_metric(metric, opts)
  end
end
