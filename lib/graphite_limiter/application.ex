defmodule GraphiteLimiter.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application
  @dest_port Application.get_env(:graphite_limiter, :graphite_dest_relay_port)

  def start(_type, _args) do
    # List all child processes to be supervised
    GraphiteLimiter.MetricsExporter.setup()
    GraphiteLimiter.Instrumenter.setup()
    children = [
      Plug.Adapters.Cowboy.child_spec(:http, GraphiteLimiter.MetricsExporter, [], port: 8080),
      {GraphiteFetcher, name: GraphiteFetcher},
      {GraphiteLimiter, name: GraphiteLimiter},
      {Task.Supervisor, name: GraphiteReceiver.TaskSupervisor},
      Supervisor.child_spec({Task, fn -> GraphiteReceiver.accept(2003) end}, restart: :permanent),
    ]
    opts = [strategy: :one_for_one, name: GraphiteLimiter.Supervisor]

    if  Application.get_env(:graphite_limiter, :run_test_server) do
      children
      |> List.insert_at(0, Supervisor.child_spec(
        {Task, fn -> GraphiteTestServer.accept(@dest_port) end},
        id: :test_task, restart: :permanent))
      |> List.insert_at(0, Supervisor.child_spec(
        {Task.Supervisor, name: DummyServer.TaskSupervisor}, id: :test))
      |> Supervisor.start_link(opts)
    else
      Supervisor.start_link(children, opts)
    end
    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
  end
end
