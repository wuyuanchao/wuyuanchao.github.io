---
title: "Beats"
weight: 1
bookFlatSection: false
# bookToc: true
# bookHidden: false
bookCollapseSection: true
# bookComments: false
# bookSearchExclude: false
---


## Beats - The Lightweight Shippers of the Elastic Stack

The Beats are lightweight data shippers, written in Go, that you install on your servers to capture all sorts of operational data (think of logs, metrics, or network packet data). The Beats send the operational data to Elasticsearch, either directly or via Logstash, so it can be visualized with Kibana.

<https://www.elastic.co/beatsi>

### the officially supported Beats:

Beat  | Description
--- | ---
[Auditbeat](https://github.com/elastic/beats/tree/main/auditbeat) | Collect your Linux audit framework data and monitor the integrity of your files.
[Filebeat](https://github.com/elastic/beats/tree/main/filebeat) | Tails and ships log files
[Functionbeat](https://github.com/elastic/beats/tree/main/x-pack/functionbeat) | Read and ships events from serverless infrastructure.
[Heartbeat](https://github.com/elastic/beats/tree/main/heartbeat) | Ping remote services for availability
[Metricbeat](https://github.com/elastic/beats/tree/main/metricbeat) | Fetches sets of metrics from the operating system and services
[Packetbeat](https://github.com/elastic/beats/tree/main/packetbeat) | Monitors the network and applications by sniffing packets
[Winlogbeat](https://github.com/elastic/beats/tree/main/winlogbeat) | Fetches and ships Windows Event logs
[Osquerybeat](https://github.com/elastic/beats/tree/main/x-pack/osquerybeat) | Runs Osquery and manages interraction with it.

### community beats

In addition to the above Beats, which are officially supported by
[Elastic](https://elastic.co), the community has created a set of other Beats
that make use of libbeat but live outside of this Github repository. We maintain
a list of community Beats
[here](https://www.elastic.co/guide/en/beats/libbeat/master/community-beats.html).
