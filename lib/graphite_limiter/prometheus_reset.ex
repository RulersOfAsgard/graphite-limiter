defmodule GraphiteLimiter.PrometheusReset do
  @moduledoc """
  Refreshes metric list periodically
  """
  require Prometheus.Registry

  alias GraphiteLimiter.Instrumenter
  alias Prometheus.Registry

  def reset(interval) do
    Registry.deregister_collector(:default, :prometheus_counter)
    Registry.register_collector(:default, :prometheus_counter)
    Instrumenter.setup()
    Process.sleep(interval)
  end
end
