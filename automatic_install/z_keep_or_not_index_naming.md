# Index Naming
the following field `_ingest.corelight_index_name_suffix` should be set under each type (below). 

## Parse Failures
- parse-failures-yyyy-MM-dd
## NSM Metadata type Logs
"_ingest.corelight_index_name_prefix": "ecs-corelight"
- ecs-corelight-conn-yyyy-MM-dd
  - conn
  "_ingest.corelight_index_name_suffix": "conn"
- ecs-corelight-dns-yyyy-MM-dd
  - dns
  "_ingest.corelight_index_name_suffix": "dns"
- ecs-corelight-files-yyyy-MM-dd
  - files
  "_ingest.corelight_index_name_suffix": "files"
- ecs-corelight-http-yyyy-MM-dd
  - http
  "_ingest.corelight_index_name_suffix": "http"
- ecs-corelight-smb-yyyy-MM-dd
  - smb_mapping
  - smb_files
  "_ingest.corelight_index_name_suffix": "smb"
- ecs-corelight-ssl-yyyy-MM-dd
  - ssl
  "_ingest.corelight_index_name_suffix": "ssl"
- ecs-corelight-suricata-yyyy-MM-dd
  - suricata
  "_ingest.corelight_index_name_suffix": "suricata"
- ecs-corelight-syslog-yyyy-MM-dd
  - syslog
  "_ingest.corelight_index_name_suffix": "syslog"
- ecs-corelight-various-yyyy-MM-dd
  - everything not defined
  "_ingest.corelight_index_name_suffix": "various"
- ecs-corelight-x509-yyyy-MM-dd
  - x509
  "_ingest.corelight_index_name_suffix": "x509"

## Metrics type
"_ingest.corelight_index_name_prefix": "corelight-zeek"
- corelight-zeek-metrics-{{event.dataset}}-yyyy-MM-dd
  - corelight_metrics_bro
  - corelight_metrics_cpu
  - corelight_metrics_disk
  - corelight_metrics_iface
  - corelight_metrics_memory
  - corelight_metrics_s3
  - corelight_metrics_sftp
  - corelight_metrics_suricata
  - corelight_metrics_system
  "_ingest.corelight_index_name_suffix": "metrics-{{event.dataset}}"
## Stats type
"_ingest.corelight_index_name_prefix": "corelight-zeek"
- corelight-zeek-stats-{{event.dataset}}-yyyy-MM-dd
  - namecache
  - loaded_scripts
  - suricata_stats
  - reporter
  - stats
  - corelight_overall_capture_loss
  - capture_loss
  - corelight_profiling
  - packet_filter
  - corelight_weird_stats
  "_ingest.corelight_index_name_suffix": "stats-{{event.dataset}}"
## System Related Info type
"_ingest.corelight_index_name_prefix": "corelight-zeek"
- corelight-zeek-system-{{event.dataset}}-yyyy-MM-dd
  - corelight_audit_log
  "_ingest.corelight_index_name_suffix": "system-{{event.dataset}}"
