## Versioning of templates, schema, etc
ecs version gets stored as `ecs.version`

corelight version gets stored as `labels.corelight.ecs_version`

ECS version is the current release of ECS that Corelight ECS is based upon.  
Corelight ECS version is based on that ECS release. and will add its iteration of this.  
For example, if the ECS version is `1.9.0` and the first release of Corelight is matching this version, then Corelight ECS version is `1.9.0.1`. Then any new updates matching `1.9.0` would increment the 4th number, so the next update would be `1.9.0.2` and so on.  
When a new release of ECS comes out (example) `1.9.0` then first release of Corelight ECS would be `1.9.0.1`

Elasticsearch template (file named `template_corelight`) version is the value of `labels.corelight.ecs_version` without the dots, so `1.9.0.1` would be `1901`

## Release notes

### 1.9.0.1
- ECS 1.9.0 support
- Corelight v21 New Logs
    - dga.log
        Part of the DGA Detection package. When DGA Detection is enabled, tracks DNS records that match known DGA patterns.
    - encrypted_dns.log
        Part of the Encrypted DNS Server Detection package. When Encrypted DNS Server Detection is enabled, reports information about detected DNS-over-HTTPS traffic.
    - generic_dns_tunnels.log
        Part of the DNS Tunnels package. When DNS Tunnels is enabled with the generic detection option, reports information about likely DNS tunnels.
    - generic_icmp_tunnels.log
        Part of the ICMP Tunnels package. When ICMP Tunnels is enabled with the generic detection option, reports information about likely ICMP tunnels.
    - meterpreter.log
        Part of the Meterpreter Detection package. When Meterpreter Detection is enabled, reports information about connections with Meterpreter-formatted headers.
    - meterpreter_headers.log
        Part of the Meterpreter Detection package. When Meterpreter Detection is enabled, reports information about connections with Meterpreter-formatted headers where the detection was made through a TCP header.
    - specific_dns_tunnels.log
        Part of the DNS Tunnels package. When DNS Tunnels is enabled, reports information about detected DNS tunnels originating from a specific set of tunneling tools.
- Corelight v21 Updated Logs
    - conn.log
        The conn log has new fields associated with the Shunting package on Corelight Sensors with enhanced NICs. These fields are only present when Shunting is enabled.
    - notice.log
        The notice log has a new severity field.
    - rdp.log
        The rdp log has new fields associated with the RDP Inference package. These fields are only present when RDP Inference is enabled.
    - ssl.log
        The encrypted_dns_resp_h field associated with the deprecated Encrypted DNS package is no longer available.
    - files.log
      - renamed `tx_host` to `files.tx_hosts`
      - renamed `rx_host` to `files.rx_hosts`
      - copied `files.tx_hosts` to `destination.ip`
      - copied `files.rx_hosts` to `source.ip`
- Collapsed the logic of xpack (licensed) VS non-xpack (opendistro AKA opensearch) into as few files as possible, separating only the very necessary components that are licensed VS non licensed
- removed `template_corelight_temporary_log_holdings`
- If a parser is not included for a log (ie: an unknown or brand new log), that log is sent to the elasticsearch index `ecs-corelight-$logname-$pattern` ex: (`ecs-corelight-some_new_log-2021-05-01`)
- `labels.dns.query_length alias` to `dns.question.name_length`



### 1.5.0.1
- ECS 1.5.0 support
- ECS TLS schema
- ECS VLAN schema
- added analyzed fields for faster searching
- supports open source Zeek now (in addition to already supporting Corelight)
- added the logic for ECS field dns.header_flags
- updated import script to support user/pass, HTTP or HTTPS, HTTPS verification on/off, and ability to specify CA certificate if using HTTPS
- fixed issues with Elasticsearch's default scripting of only 15 per minute
- source & destination IP Geo enrichment processor
- source & destination IP Geo ASN enrichment processor
- user_agent enrichment processor
- increased error checking and verbosity of information related to errors in the import script
- elasticsearch mappings
- x509 schema, from ECS 1.6 
- increased efficiency of the pipeline
- `related.ip` (for pivoting across IP addresses)
- `related.mac` (for pivoting across MAC addresses) 
- `related.id` (for pivoting across Zeek logs), use this to pivot off of the `uid` field and any other "id" fields that Zeek has in it's logs like `fuid` or `conn_uids` and so on...
- `related.domain` (for pivoting across Domains)
- NTP log
- MQTT_Connect log
- MQTT_Publish log
- MQTT_Subscribe log
- MQTT_POP3 log
- GQUIC logy
- no longer renaming fields unless specifically an ECS name to be mapped to (to reduce confusion, but more importantly to share queries/hunts with those who do NOT do a lot of transform/ETL pipelines)
- SMTP_Links log
- Conn_Long log
- HTTP2 log
- reporter log for open source Zeek
- stats log for open source Zeek
- `community_id` named to ECS `network.community_id`
- more efficient use of conn log detailed history, by using enrich processor
- include Corelight pipeline version in each document. This allows if there is a hot-fix/issue between versions, for scripts to use this field to figure out what version was used and thus implement the logic to fix the issue
- Added Corelight SSH stepping (stones) `stepping.log`
- Added Corelight Suricata `suricata_corelight.log`
- If a parser is not included for a log (ie: an unknown or brand new log), that log is sent to the elasticsearch index `temp-corelight-$logname` ex: (`temp-corelight-conn`)
- Parsing failures of logs, will be "caught" and stored in index with the naming convention of `parse-failures-$YYYY.DD.MM` ex: (`parse-failures-2020.05.01`)
- Metrics, Stats, and Capture Loss type logs are stored in index with the naming convention of `corelight-zeek-metrics-$YYYY.DD.MM` ex: (`corelight-zeek-metrics-2020.05.01`)
    - `namecache.log` fields no longer get renamed, and are now stored in `corelight-zeek-namecache`
    - `reporter.log` fields no longer get renamed, and are now stored in `corelight-zeek-reporter`
    - `stats.log` fields no longer get renamed, and are now stored in `corelight-zeek-stats`
#### Fields renamed
`previous field name: new field name` 
```yaml
All Logs:
  vlan.outer.id: network.vlan.id
  vlan.inner.id: network.vlan.inner.id

conn.log:
  network.connection.state.detailed: network.connection.state_description    
    
files.log:
  file.is_originating: file.is_orig
  files.analyzers: file.analyzers
  files.depth: file.depth
  files.duration: file.duration
  files.extracted: file.extracted
  files.extracted_cutoff: file.extracted_cutoff
  files.extracted_size: file.extracted_size
  files.entropy: file.entropy
  files.local_origin: file.local_orig
  files.timedout: file.timedout
  files.missing_bytes: file.missing_bytes
  files.overflow_bytes: file.overflow_bytes
  files.seen_bytes: file.seen_bytes


notice.log:
  dst:  notice.dst_ip # gets copied to destination.ip it does not exist already from `id.resp_h`
  src:  notice.src_ip # gets copied to source.ip it does not exist already from `id.orig_h`

software.log:
  software.additional: software.version.additional_info
  software.major: software.version.major
  software.minor: software.version.minor
  software.minor2: software.version.minor2
  software.minor3: software.version.minor3

x509.log:
  x509.certificate.basic_constraints.ca: file.x509.certificate.basic_constraints.ca
  x509.certificate.basic_constraints.path_length: file.x509.certificate.basic_constraints.path_length
  x509.certificate.common_name: file.x509.certificate.common_name
  x509.certificate.elliptic_curve: file.x509.public_key_curve
  x509.certificate.exponent: file.x509.certificate.exponent
  x509.certificate.issuer: file.x509.issuer.distinguished_name
  x509.certificate.key_algorithm: file.x509.public_key_algorithm
  x509.certificate.key_length: file.x509.public_key_size
  x509.certificate.key_type: file.x509.public_key_type
  x509.certificate.not_valid_after: file.x509.not_after
  x509.certificate.not_valid_before: file.x509.not_before
  x509.certificate.serial: file.x509.serial_number
  x509.certificate.sig_alg: file.x509.signature_algorithm
  x509.certificate.subject: file.x509.subject.distinguished_name
  x509.certificate.version: file.x509.version_number
  x509.logcert: file.x509.logcert
  x509.san.dns: file.x509.san_dns
  x509.san.email: file.x509.san_email
  x509.san.ip: file.x509.san_ip
  x509.san.url: file.x509.san_url
```

# To-Do #TODO:
- [ ] set processor in later version of Elasticsearch (>= 7.9 ) has an option called `ignore_empty_value` - which would free up hundreds of CPU cycles per pipeline (ie: having to check if exists and if NOT null) - description of processor is `if evaluates to null or the empty string`
- [ ] set processor in later version of Elasticsearch (>= 7.11 ) has an option called `copy_from` - which would make easier basically copying fields/values instead of using `{{$FieldName}}`
