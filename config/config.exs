# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

# This configuration is loaded before any dependency and is restricted
# to this project. If another project depends on this project, this
# file won't be loaded nor affect the parent project. For this reason,
# if you want to provide default values for your application for
# 3rd-party users, it should be done in your "mix.exs" file.

# You can configure your application as:
#
#     config :graphite_limiter, key: :value
#
# and access this configuration in your application as:
#
#     Application.get_env(:graphite_limiter, :key)
#
# You can also configure a 3rd-party app:
#
#     config :logger, level: :info
#

# It is also possible to import configuration files, relative to this
# directory. For example, you can emulate configuration per environment
# by uncommenting the line below and defining dev.exs, test.exs and such.
# Configuration from the imported file will override the ones defined
# here (which is why it is important to import them last).
config :logger, :console, format: "$time [$level] $metadata $message\n",
  metadata: [:module, :function]

config :prometheus, GraphiteLimiter.PlugExporter, # (you should replace this with the name of your plug)
  path: "/metrics",
  format: :auto, ## or :protobuf, or :text
  registry: :default,
  auth: false

config :graphite_limiter,
  graphite_url: "http://skywebs.qxlint/render/",
  graphite_query:
    "aliasByNode(highestMax(summarize(aggregated.counters.stats.tech.monitoring.rates.stats.*.*.*.count,\"2minutes\",\"sum\"), 15), 6, 7, 8, 9)",
  graphite_dest_relay_addr: 'skystats.qxlint',
  graphite_api_module: GraphiteApi

import_config "#{Mix.env()}.exs"
