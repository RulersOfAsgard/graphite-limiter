defmodule GraphiteLimiter.PrometheusReset do
  @moduledoc """
  Refreshes metric list periodically
  """
  require Prometheus.Registry

  alias GraphiteLimiter.{Instrumenter, MetricsExporter}
  alias Prometheus.Registry

  def reset(interval) do
    :ok = Registry.clear()
    Instrumenter.setup()
    MetricsExporter.setup()
    Process.sleep(interval)
  end
end
