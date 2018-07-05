use Mix.Config

config :graphite_limiter,
run_test_server: false,
limit: 100_000,
graphite_url: "http://skywebs.qxlint/render/",
graphite_query:
  "aliasByNode(highestMax(summarize(aggregated.counters.stats.tech.monitoring.rates.stats.*.*.*.count,\"2minutes\",\"sum\"), 15), 6, 7, 8, 9)",
graphite_dest_relay_addr: 'skystats.qxlint',
graphite_dest_relay_port: 2003,
graphite_api_module: GraphiteApi
