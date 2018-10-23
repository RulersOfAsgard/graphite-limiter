defmodule GraphiteApi do
  @moduledoc false
  use Tesla
  require Logger

  @behaviour MetricsApi.Impl

  plug(Tesla.Middleware.BaseUrl, Application.get_env(:graphite_limiter, :graphite_url))

  plug(
    Tesla.Middleware.Query,
    from: "-2minutes",
    target: Application.get_env(:graphite_limiter, :graphite_query),
    format: "json"
  )

  plug(Tesla.Middleware.JSON)

  @spec get_metrics() :: {:error, any} | {:ok, map}
  def get_metrics do
    get("")
  end
end
