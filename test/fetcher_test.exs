defmodule GraphitFetcherTest do
  use ExUnit.Case, async: false
  import Mock
  require Logger

  setup do
    :ok
  end

  test "update_cache" do
    Process.send(GraphiteFetcher, :update_cache, [])
    :sys.get_state(GraphiteFetcher)
    resp = GenServer.call(GraphiteFetcher, :get_paths)
    |> Enum.sort

    assert resp == ["stats.other.overloaded.path", "stats.overloaded.path"]
  end

  test "connection error on cache update" do
    with_mock GraphiteApi.Mock, [get_metrics: fn() -> {:error, :econrefused} end] do
      Process.send(GraphiteFetcher, :update_cache, [])
      :sys.get_state(GraphiteFetcher)
      assert GenServer.call(GraphiteFetcher, :get_paths) == []
    end
  end
end
