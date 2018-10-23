use Mix.Config

config :graphite_limiter,
run_test_server: true,
limit: 1000,
sender_pool: 0,
graphite_url: "http://localhost/render",
graphite_dest_relay_addr: "localhost",
graphite_dest_relay_port: 2004,
prometheus_query: "irate(metrics_by_path_total{}[2m])",
prometheus_url: "http://localhost:9090"
