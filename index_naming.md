# Index Naming
the following field `temporary_metadata_index_name_suffix` should be set under each type (below). 

## Parse Failures
- parse-failures-yyyy-MM-dd
## NSM Metadata type Logs
"temporary_metadata_index_name_prefix": "ecs-corelight"
- ecs-corelight-conn-yyyy-MM-dd
  - conn
  "temporary_metadata_index_name_suffix": "conn"
- ecs-corelight-dns-yyyy-MM-dd
  - dns
  "temporary_metadata_index_name_suffix": "dns"
- ecs-corelight-files-yyyy-MM-dd
  - files
  "temporary_metadata_index_name_suffix": "files"
- ecs-corelight-http-yyyy-MM-dd
  - http
  "temporary_metadata_index_name_suffix": "http"
- ecs-corelight-smb-yyyy-MM-dd
  - smb_mapping
  - smb_files
  "temporary_metadata_index_name_suffix": "smb"
- ecs-corelight-ssl-yyyy-MM-dd
  - ssl
  "temporary_metadata_index_name_suffix": "ssl"
- ecs-corelight-suricata-yyyy-MM-dd
  - suricata
  "temporary_metadata_index_name_suffix": "suricata"
- ecs-corelight-syslog-yyyy-MM-dd
  - syslog
  "temporary_metadata_index_name_suffix": "syslog"
- ecs-corelight-various-yyyy-MM-dd
  - everything not defined
  "temporary_metadata_index_name_suffix": "various"
- ecs-corelight-x509-yyyy-MM-dd
  - x509
  "temporary_metadata_index_name_suffix": "x509"

## Metrics type
"temporary_metadata_index_name_prefix": "zeek-corelight"
- zeek-corelight-metrics-{{event.dataset}}-yyyy-MM-dd
  - corelight_metrics_bro
  - corelight_metrics_cpu
  - corelight_metrics_disk
  - corelight_metrics_iface
  - corelight_metrics_memory
  - corelight_metrics_s3
  - corelight_metrics_sftp
  - corelight_metrics_suricata
  - corelight_metrics_system
  "temporary_metadata_index_name_suffix": "metrics-{{event.dataset}}"
## Netcontrol type
"temporary_metadata_index_name_prefix": "zeek-corelight"
- zeek-corelight-netcontrol-{{event.dataset}}-yyyy-MM-dd
  - netcontrol
  - netcontrol_drop
  - netcontrol_shunt
  "temporary_metadata_index_name_suffix": "netcontrol-{{event.dataset}}"
## Stats type
"temporary_metadata_index_name_prefix": "zeek-corelight"
- zeek-corelight-stats-{{event.dataset}}-yyyy-MM-dd
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
  "temporary_metadata_index_name_suffix": "stats-{{event.dataset}}"
## System Related Info type
"temporary_metadata_index_name_prefix": "zeek-corelight"
- zeek-corelight-system-{{event.dataset}}-yyyy-MM-dd
  - corelight_audit_log
  "temporary_metadata_index_name_suffix": "system-{{event.dataset}}"
