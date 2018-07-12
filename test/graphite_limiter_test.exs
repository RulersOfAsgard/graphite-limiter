defmodule GraphiteLimiterTest do
  @moduledoc false
  use ExUnit.Case, async: true
  use Plug.Test
  @moduletag :capture_log
  import ExUnit.CaptureLog
  require Logger
  require Prometheus.Metric.Counter

  @good_path "good.path"
  @bad_path "stats.overloaded.path"
  @good_metric "#{@good_path}.metric 2 1528446600\n"
  @bad_metric "#{@bad_path}.metric 2 1528446600\n"

  @data "local.random.diceroll 4 1528366588\n"

  setup do
    opts = [:binary, packet: :line, active: false]
    {:ok, socket} = :gen_tcp.connect('localhost', 2003, opts)
    Prometheus.Metric.Counter.reset(:metrics_received_total)
    Prometheus.Metric.Counter.reset(:metrics_sent_total)
    Prometheus.Metric.Counter.reset(:metrics_blocked_total)
    %{socket: socket}
  end

  defp send_data(socket, data) do
    Logger.warn("HELLLLLLLO")
    :ok = :gen_tcp.send(socket, data)
  end

  describe "Integration tests" do
    test "receiving_and_parsing_messages", %{socket: socket} do
      assert capture_log(fn ->
        send_data(socket, @data)
        Process.sleep(100)
      end) =~ "Test Server received: #{@data}"
      assert Prometheus.Metric.Counter.value(:metrics_received_total) == 1
      assert Prometheus.Metric.Counter.value(:metrics_sent_total) == 1

      assert capture_log(fn ->
        send_data(socket, @good_metric)
        Process.sleep(100)
      end) =~ "Test Server received: #{@good_metric}"
      assert Prometheus.Metric.Counter.value(:metrics_sent_total) == 2
    end

    test "if metric is blocked correctly" do
      Process.send(GraphiteFetcher, :update_cache, [])
      assert capture_log(fn ->
        GraphiteLimiter.parse_metric(@bad_metric) end) =~
          "Metric `#{String.trim_trailing(@bad_metric, "\n")}` blocked"
      assert Prometheus.Metric.Counter.value(:metrics_blocked_total) == 1
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
