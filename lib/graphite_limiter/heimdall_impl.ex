defmodule GraphiteLimiter.HeimdallImpl do
  @moduledoc """
  Documentation for GraphiteLimiter.
  """
  require Logger

  @behaviour GraphiteLimiter.Impl

  @spec parse_metric(String.t, map) :: :ok
  def parse_metric(metric, %{sender_pool_size: sender_pool_size}) do
    GraphiteLimiter.Router.validate_metric({metric, :valid}, sender_pool_size)
  end
end
