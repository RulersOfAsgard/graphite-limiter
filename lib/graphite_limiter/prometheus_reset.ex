defmodule GraphiteLimiter.PrometheusReset do
  @moduledoc """
  Refreshes metric list periodically
  """
  require Prometheus.Registry
  require Logger

  alias GraphiteLimiter.Instrumenter
  alias Prometheus.Registry

  def reset(interval) do
    Logger.debug("Reseting Prometheus Collector")
    Registry.deregister_collector(:default, :prometheus_counter)
    Registry.register_collector(:default, :prometheus_counter)
    Instrumenter.setup()
    Process.sleep(interval)
  end
end
