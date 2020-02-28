defmodule PrometheusApiTest do
  @moduledoc false
  use ExUnit.Case, async: false
  # import Mock
  require Logger

  @bad_url "http://localhost:9090/api/v1/query_range"

  setup do
    Tesla.Mock.mock(fn
      %{method: :get, url: @bad_url} ->
        %Tesla.Env{
          status: 200,
          body: "404 page not found\n",
          headers: [
            {"content-type", "text/plain; charset=utf-8"}
          ]
        }
    end)

    :ok
  end

  test "Prometheus is not returning json" do
    assert {:error, []} = PrometheusApi.get_metrics()
  end
end
