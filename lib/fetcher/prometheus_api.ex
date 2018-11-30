defmodule PrometheusApi.Result do
  @moduledoc false
  defstruct [metric: %{}, values: []]
end

defmodule PrometheusApi do
  @moduledoc false
  use Tesla
  require Logger
  alias PrometheusApi.Result

  @behaviour MetricsApi.Impl

  plug(Tesla.Middleware.BaseUrl, Application.get_env(:graphite_limiter, :prometheus_url))

  plug(
    Tesla.Middleware.Query,
    query: Application.get_env(:graphite_limiter, :prometheus_query),
    step: "60s"
  )

  plug(Tesla.Middleware.JSON)

  @spec get_metrics() :: {:error, any} | {:ok, map}
  def get_metrics do
    now = DateTime.utc_now
    |> DateTime.to_unix
    with {:ok, response} <- get("api/v1/query_range", query: [start: now - 600, end: now]),
         true <- is_list(response.body["data"]["result"]) do
          response.body["data"]["result"]
          |> serialize
          |> fn(results) -> {:ok, %{body: results}} end.()
    else
      _ -> {:error, []}
    end
  end

  @spec serialize(list(%Result{})) :: any
  defp serialize(results) do
    results
    |> Enum.map(fn(x) ->
      datapoints = x["values"]
      |> Enum.map(fn([timestamp, value]) ->
        int_value = value
        |> to_integer
        [int_value, timestamp] end)
      %{"target" => x["metric"]["path"], "datapoints" => datapoints}
    end)
  end

  @spec to_integer(String.t) :: integer
  defp to_integer(value) do
    {int, _} = value
    |> Integer.parse
    int
  end
end
