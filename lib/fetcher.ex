defmodule GraphiteFetcher do
  @moduledoc """
  Module responsible for fetching data about metrics creation volumes
  """
  use GenServer
  require Logger

  @graphite_api Application.get_env(:graphite_limiter, :graphite_api_module, GraphiteApi)

  # client api

  def start_link(opts) do
    server = Keyword.fetch!(opts, :name)
    GenServer.start_link(__MODULE__, server, opts)
  end

  # server callbacks

  def init(server) do
    metric_paths = :ets.new(server, [:named_table, read_concurrency: true])
    refs = %{}
    schedule_next_run(server, 100)
    {:ok, {metric_paths, refs}}
  end

  def handle_call(:get_paths, _from, {metric_paths, _refs} = state) do
    resp = with [paths: paths] <- :ets.lookup(metric_paths, :paths) do
      paths
    else
      _ -> []
    end
    {:reply, resp, state}
  end

  def handle_info(:update_cache, {metric_table, refs}) do
    fetch_data()
    |> filter
    |> save(metric_table)
    |> schedule_next_run(60_000)
    {:noreply, {metric_table, refs}}
  end

  @spec save(list(String.t), :ets.tid) :: atom | :ets.tid
  defp save(metric_paths, metric_table) do
    Logger.debug(fn -> inspect(metric_paths) end)
    :ets.insert(metric_table, {:paths, metric_paths})
    metric_table
  end

  @spec filter(list(map)) :: list(String.t)
  defp filter(data) do
    data
    |> Enum.reduce([], fn(metric, heavy_metrics) ->
      metric
      |> filter_datapoints_above_limit
      |> extract_target_field
      |> Enum.concat(heavy_metrics)
    end)
  end

  defp filter_datapoints_above_limit(%{"datapoints" => datapoints} = metric) do
    points_above_limit = datapoints
    |> Enum.reject(fn([value, _timestamp]) ->
      case value do
        nil -> true
         x -> x < Application.get_env(:graphite_limiter, :limit, 100_000)
      end
    end)
    {points_above_limit, metric}
  end

  defp extract_target_field({[], _metric}), do: []
  defp extract_target_field({[[_, _] | _tail], metric}), do: [metric["target"]]

  defp fetch_data do
    case @graphite_api.get_metrics() do
       {:ok, response} -> response.body
       {:error, _err} -> []
    end
  end

  defp schedule_next_run(server, delay) do
    Process.send_after(server, :update_cache, delay, [])
  end
end
