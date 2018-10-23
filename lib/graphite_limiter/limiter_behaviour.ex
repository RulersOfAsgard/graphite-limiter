defmodule GraphiteLimiter.Impl do
  @moduledoc """
  Behaviour for GraphiteLimiter module
  """
  @callback parse_metric(String.t, integer) :: :ok
end
