use Mix.Config

config :logger, :console,
level: :info,
discard_threshold: 2000

config :graphite_limiter,
run_test_server: false,
limit: 100_000
