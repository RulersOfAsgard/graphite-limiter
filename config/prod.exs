use Mix.Config

config :logger,
  backends: [:console],
  discard_threshold: 2000,
  compile_time_purge_matching: [
    [level_lower_than: :info]
  ]

config :logger, :console,
level: :info

config :graphite_limiter,
run_test_server: false,
limit: 100_000
