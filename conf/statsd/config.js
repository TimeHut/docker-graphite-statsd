{
  graphitePort: 2003
, graphiteHost: "127.0.0.1"
, graphite: { legacyNamespace: false }
, port: 8125
, flushInterval: 10000
, backends: [ "./backends/graphite" ]
}