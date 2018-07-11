defmodule GraphiteApi do
  @moduledoc false
  use Tesla
  require Logger

  plug(Tesla.Middleware.BaseUrl, Application.get_env(:graphite_limiter, :graphite_url))

  plug(
    Tesla.Middleware.Query,
    from: "-2minutes",
    target: Application.get_env(:graphite_limiter, :graphite_query),
    format: "json"
  )

  plug(Tesla.Middleware.JSON)

  def get_metrics do
    get("")
  end
end
