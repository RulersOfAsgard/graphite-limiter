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
    Counter.declare([name: :metrics_dropped_total,
                    help: "Metrics dropped count.",
                    labels: []])
    Counter.declare([name: :errors_received_total,
                    help: "errors on metrics receive count.",
                    labels: [:type]])
    Counter.declare([name: :errors_sent_total,
                    help: "errors on metrics sent count.",
                    labels: [:type]])
    Counter.declare([name: :metrics_by_path_total,
                     help: "Metrics by path count",
                     labels: [:path]])
  end

  @spec inc_errors_received(atom) :: :ok
  def inc_errors_received(type) do
    Counter.inc([name: :errors_received_total, labels: [type]])
  end

  @spec inc_errors_sent(atom) :: :ok
  def inc_errors_sent(type) do
    Counter.inc([name: :errors_sent_total, labels: [type]])
  end

  @spec inc_metrics_received :: :ok
  def inc_metrics_received do
    Counter.inc([name: :metrics_received_total, labels: []])
  end

  @spec inc_metrics_sent :: :ok
  def inc_metrics_sent do
    Counter.inc([name: :metrics_sent_total, labels: []])
  end

  @spec inc_metrics_sent(number) :: :ok
  def inc_metrics_sent(value) do
    Counter.inc([name: :metrics_sent_total, labels: []], value)
  end

  @spec inc_metrics_blocked :: :ok
  def inc_metrics_blocked do
    Counter.inc([name: :metrics_blocked_total, labels: []])
  end

  @spec inc_metrics_dropped :: :ok
  def inc_metrics_dropped do
    Counter.inc([name: :metrics_dropped_total, labels: []])
  end

  @spec inc_metrics_by_path(String.t) :: :ok
  def inc_metrics_by_path(path) do
    Counter.inc([name: :metrics_by_path_total, labels: [path]])
  end
end

defmodule GraphiteLimiter.MetricsExporter do
  @moduledoc """
  Prometheus plug exporter
  """
  use Prometheus.PlugExporter
end