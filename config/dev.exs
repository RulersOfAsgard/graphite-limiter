use Mix.Config

config :graphite_limiter,
run_test_server: false,
limit: 100,
sender_pool: 1,
graphite_url: "http://skystats-dev.qxlint/render/",
graphite_dest_relay_addr: "localhost",
graphite_dest_relay_port: 2004
