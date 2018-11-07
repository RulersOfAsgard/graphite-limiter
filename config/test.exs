use Mix.Config

config :graphite_limiter,
  limit: 100,
  sender_pool: 1,
  send_buffer: 0,
  graphite_url: "http://localhost/render/",
  graphite_query: "sample.path.to.metric",
  graphite_dest_relay_addr: "localhost",
  graphite_dest_relay_port: 2004,
  metrics_api_module: GraphiteApi.Mock,
  run_test_server: true,
  path_whitelist: ["carbon.monitoring.test"]
