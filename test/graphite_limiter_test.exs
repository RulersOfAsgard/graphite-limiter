defmodule GraphiteLimiterTest do
  @moduledoc false
  use ExUnit.Case, async: true
  use Plug.Test
  @moduletag :capture_log
  import ExUnit.CaptureLog
  require Logger
  require Prometheus.Metric.Counter

  @good_path "good.path.min.metric"
  @bad_path "stats.overloaded.path.metric"
  @good_metric "#{@good_path}.foo 2 1528446600\n"
  @bad_metric "#{@bad_path}.bar 2 1528446600\n"

  @white_list_path "carbon.monitoring.test.foo"
  @white_list_metric "#{@white_list_path} 4 1528366588\n"
  @to_short "to.short.metric 4 1528366588\n"

  setup do
    opts = [:binary, packet: :line, active: false]
    {:ok, socket} = :gen_tcp.connect('localhost', 2003, opts)
    Prometheus.Metric.Counter.reset(:metrics_received_total)
    Prometheus.Metric.Counter.reset(:metrics_sent_total)
    Prometheus.Metric.Counter.reset(:metrics_blocked_total)
    Prometheus.Metric.Counter.reset(:metrics_dropped_total)
    %{socket: socket}
  end

  defp send_data(socket, data) do
    :ok = :gen_tcp.send(socket, data)
  end

  describe "Integration tests" do
    test "receiving_and_parsing_messages", %{socket: socket} do
      assert capture_log(fn ->
        send_data(socket, @good_metric)
        Process.sleep(100)
      end) =~ "Test Server received: #{@good_metric}"
      assert Prometheus.Metric.Counter.value(:metrics_received_total) == 1
      assert Prometheus.Metric.Counter.value(
        [name: :metrics_by_path_total, labels: [@good_path]]) == 1
      assert Prometheus.Metric.Counter.value(:metrics_sent_total) == 1
    end

    test "if metric is blocked correctly" do
      Process.send(GraphiteFetcher, :update_cache, [])
      sender_pool = Application.get_env(:graphite_limiter, :sender_pool)
      GraphiteLimiter.parse_metric(@bad_metric, sender_pool)
      assert Prometheus.Metric.Counter.value(:metrics_blocked_total) == 1
      assert Prometheus.Metric.Counter.value(:metrics_sent_total) == 0
    end

    test "if metric is dropped" do
      sender_pool = Application.get_env(:graphite_limiter, :sender_pool)
      GraphiteLimiter.parse_metric(@to_short, sender_pool)
      assert Prometheus.Metric.Counter.value(:metrics_blocked_total) == 0
      assert Prometheus.Metric.Counter.value(:metrics_sent_total) == 0
      assert Prometheus.Metric.Counter.value(:metrics_dropped_total) == 1
    end

    test "if metric is sent when path is on white_list", %{socket: socket} do
      assert capture_log(fn ->
        send_data(socket, @white_list_metric)
        Process.sleep(100)
      end) =~ "Test Server received: #{@white_list_metric}"
      assert Prometheus.Metric.Counter.value(
        name: :metrics_by_path_total, labels: [@white_list_path]) == :undefined
      assert Prometheus.Metric.Counter.value(:metrics_blocked_total) == 0
      assert Prometheus.Metric.Counter.value(:metrics_sent_total) == 1
      assert Prometheus.Metric.Counter.value(:metrics_dropped_total) == 0
    end
  end

  describe "Http endpoints tests" do
    test "if /metrics returns data" do
      conn =
        conn(:get, "/metrics", "")
        |> GraphiteLimiter.MetricsExporter.call([])
      assert conn.status == 200
      assert String.starts_with?(conn.resp_body, "# TYPE")
    end
  end

end
