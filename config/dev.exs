use Mix.Config

config :graphite_limiter,
run_test_server: false,
limit: 100,
graphite_dest_relay_addr: "localhost",
graphite_dest_relay_port: 2004
