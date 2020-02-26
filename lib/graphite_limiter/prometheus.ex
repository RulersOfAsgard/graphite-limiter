defmodule GraphiteLimiter.Instrumenter do
  @moduledoc """
  Prometheus Instrumenter
  """
  use Prometheus.Metric

  def setup do
    Counter.declare(
      name: :metrics_received_total,
      help: "Metrics received count.",
      labels: []
    )

    Counter.declare(
      name: :metrics_sent_total,
      help: "Metrics sent count.",
      labels: []
    )

    Counter.declare(
      name: :metrics_blocked_total,
      help: "Metrics blocked count.",
      labels: []
    )

    Counter.declare(
      name: :metrics_dropped_total,
      help: "Metrics dropped count.",
      labels: []
    )

    Counter.declare(
      name: :errors_received_total,
      help: "errors on metrics receive count.",
      labels: [:type]
    )

    Counter.declare(
      name: :errors_sent_total,
      help: "errors on metrics sent count.",
      labels: [:type]
    )

    Counter.declare(
      name: :metrics_by_path_total,
      help: "Metrics by path count",
      labels: [:path]
    )

    Gauge.declare(
      name: :queue_length,
      help: "Message queue length",
      labels: [:process]
    )
  end

  @spec inc_errors_received(atom) :: :ok
  def inc_errors_received(type) do
    Counter.inc(name: :errors_received_total, labels: [type])
  rescue
    Prometheus.UnknownMetricError -> :ok
  end

  @spec inc_errors_sent(atom) :: :ok
  def inc_errors_sent(type) do
    Counter.inc(name: :errors_sent_total, labels: [type])
  rescue
    Prometheus.UnknownMetricError -> :ok
  end

  @spec inc_metrics_received :: :ok
  def inc_metrics_received do
    Counter.inc(name: :metrics_received_total, labels: [])
  rescue
    Prometheus.UnknownMetricError -> :ok
  end

  @spec inc_metrics_sent :: :ok
  def inc_metrics_sent do
    Counter.inc(name: :metrics_sent_total, labels: [])
  rescue
    Prometheus.UnknownMetricError -> :ok
  end

  @spec inc_metrics_sent(number) :: :ok
  def inc_metrics_sent(value) do
    Counter.inc([name: :metrics_sent_total, labels: []], value)
  rescue
    Prometheus.UnknownMetricError -> :ok
  end

  @spec inc_metrics_blocked :: :ok
  def inc_metrics_blocked do
    Counter.inc(name: :metrics_blocked_total, labels: [])
  rescue
    Prometheus.UnknownMetricError -> :ok
  end

  @spec inc_metrics_dropped :: :ok
  def inc_metrics_dropped do
    Counter.inc(name: :metrics_dropped_total, labels: [])
  rescue
    Prometheus.UnknownMetricError -> :ok
  end

  @spec inc_metrics_by_path(String.t()) :: :ok
  def inc_metrics_by_path(path) do
    Counter.inc(name: :metrics_by_path_total, labels: [path])
  rescue
    Prometheus.UnknownMetricError -> :ok
  end

  @spec queue_length(atom) :: integer
  def queue_length(process) when is_atom(process) do
    {:message_queue_len, length} =
      process
      |> Process.whereis()
      |> Process.info(:message_queue_len)

    try do
      Gauge.set([name: :queue_length, labels: [process]], length)
    rescue
      Prometheus.UnknownMetricError -> :ok
    end

    length
  end
end

defmodule GraphiteLimiter.MetricsExporter do
  @moduledoc """
  Prometheus plug exporter
  """
  use Prometheus.PlugExporter
end
