use Mix.Config

config :logger, :console,
level: :info

config :graphite_limiter,
run_test_server: false,
limit: 100_000
