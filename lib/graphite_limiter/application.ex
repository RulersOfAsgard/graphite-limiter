defmodule GraphiteLimiter.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application
  @dest_port Application.get_env(:graphite_limiter, :graphite_dest_relay_port)

  defp set_env(sys_env, app_env) do
    env = System.get_env(sys_env) || Application.get_env(:graphite_limiter, app_env)
    if is_number(Application.get_env(:graphite_limiter, app_env)) do
      int_env = String.to_integer(env)
      Application.put_env(:graphite_limiter, app_env, int_env)
    else
      Application.put_env(:graphite_limiter, app_env, env)
    end
  end

  defp runtime_configuration do
    set_env("GRAPHITE_FETCH_URL", :graphite_url)
    set_env("GRAPHITE_QUERY", :graphite_query)
    set_env("GRAPHITE_FETCH_URL", :graphite_url)
    set_env("GRAPHITE_DEST_ADDR", :graphite_dest_relay_addr)
    set_env("GRAPHITE_DEST_PORT", :graphite_dest_relay_port)
  end

  def start(_type, _args) do
    runtime_configuration()
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
