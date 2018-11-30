defmodule MetricsApi.Impl do
@moduledoc false
  @callback get_metrics() :: {:error, any} | {:ok, map}
end
