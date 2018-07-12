defmodule GraphiteLimiter.Instrumenter do
  @moduledoc """
  Prometheus Instrumenter
  """
  use Prometheus.Metric

  def setup do
    Counter.declare([name: :metrics_received_total,
                     help: "Metrics received count.",
                     labels: []])
    Counter.declare([name: :metrics_sent_total,
                    help: "Metrics sent count.",
                    labels: []])
    Counter.declare([name: :metrics_blocked_total,
                    help: "Metrics blocked count.",
                    labels: []])
    Counter.declare([name: :errors_received_total,
                    help: "errors on metrics receive count.",
                    labels: [:type]])
    Counter.declare([name: :errors_sent_total,
                    help: "errors on metrics sent count.",
                    labels: [:type]])
  end

  def inc_errors_received(type) do
    Counter.inc([name: :errors_received_total, labels: [type]])
  end

  def inc_errors_sent(type) do
    Counter.inc([name: :errors_sent_total, labels: [type]])
  end

  def inc_metrics_received do
    Counter.inc([name: :metrics_received_total, labels: []])
  end
  def inc_metrics_sent do
    Counter.inc([name: :metrics_sent_total, labels: []])
  end
  def inc_metrics_sent(value) do
    Counter.inc([name: :metrics_sent_total, labels: []], value)
  end
  def inc_metrics_blocked do
    Counter.inc([name: :metrics_blocked_total, labels: []])
  end
end

defmodule GraphiteLimiter.MetricsExporter do
  @moduledoc """
  Prometheus plug exporter
  """
  use Prometheus.PlugExporter
end
