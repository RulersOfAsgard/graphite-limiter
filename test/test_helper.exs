ExUnit.start()

defmodule GraphiteApi.Mock do
  def get_metrics() do
    data = [
      %{
        "datapoints" => [[804.0, 1528446480], [740, 1528446600]],
        "target" => "stats.other.overloaded.path"
      },
      %{
        "datapoints" => [[430.0, 1528446480], [nil, 1528446600]],
        "target" => "stats.overloaded.path"
      },
      %{
        "datapoints" => [[15.0, 1528446480], [nil, 1528446600]],
        "target" => "stats.normal.path"
      }
    ]
    {:ok, %{body: data}}
  end
end
