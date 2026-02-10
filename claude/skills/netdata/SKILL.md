---
name: netdata
description: Use when analyzing server performance, diagnosing resource issues, investigating alerts, or making optimization recommendations using Netdata API
---

# Netdata API Reference

Reference for Netdata API v3 to query metrics, investigate alerts, detect anomalies, and make server optimization recommendations.

## Quick Start

Base URL: `http://localhost:19999` (default local agent)

```bash
# Test connectivity
curl -s http://localhost:19999/api/v3/info | jq .version

# Bearer token (if enabled via /api/v3/bearer_protection)
curl -H "Authorization: Bearer <token>" http://localhost:19999/api/v3/data?contexts=system.cpu
```

Override base URL with environment variable or pass directly. Netdata Cloud agents use `https://<cloud-url>`.

## Performance Analysis Workflow

1. **Check alerts first** — `GET /api/v3/alerts?status=WARNING,CRITICAL`
2. **Investigate anomalies** — `GET /api/v3/weights?method=anomaly-rate&after=-900&before=0`
3. **Query specific metrics** — `GET /api/v3/data?contexts=<context>&after=-3600`
4. **Inspect processes** — `GET /api/v3/function?function=processes`
5. **Make recommendations** based on data

## Common Operations

| Goal | API Call |
|------|----------|
| CPU usage | `/api/v3/data?contexts=system.cpu&after=-600` |
| Memory/RAM | `/api/v3/data?contexts=system.ram&after=-600` |
| Disk I/O | `/api/v3/data?contexts=disk.io&after=-600` |
| Disk space | `/api/v3/data?contexts=disk.space&after=-600` |
| Network throughput | `/api/v3/data?contexts=net.net&after=-600` |
| Network errors/drops | `/api/v3/data?contexts=net.drops&after=-600` |
| System load | `/api/v3/data?contexts=system.load&after=-600` |
| Alert status | `/api/v3/alerts?status=WARNING,CRITICAL` |
| Alert history | `/api/v3/alert_transitions?last=20` |
| Anomaly detection | `/api/v3/weights?method=anomaly-rate&after=-300` |
| Running processes | `/api/v3/function?function=processes` |
| Systemd services | `/api/v3/function?function=systemd-list-units` |
| Network connections | `/api/v3/function?function=network-connections` |
| Docker containers | `/api/v3/function?function=docker-containers` |
| Discover metrics | `/api/v3/contexts` |
| Export all metrics | `/api/v3/allmetrics?format=json` |

## Key Endpoints

### `/api/v3/data` — Query Metrics

Primary endpoint for all metric queries. Supports multi-node, multi-context queries.

| Parameter | Default | Description |
|-----------|---------|-------------|
| `contexts` | `*` | Metric context filter (simple pattern). e.g. `system.cpu`, `disk.*` |
| `after` | `-600` | Start time. Negative = seconds relative to `before`. Positive = unix epoch |
| `before` | `0` (now) | End time. Same format as `after` |
| `points` | `0` (all) | Number of data points to return |
| `group_by` | `dimension` | Grouping: `dimension`, `instance`, `node`, `label`, `context`, `units` |
| `group_by_label` | — | Label key(s) for `group_by=label` |
| `aggregation` | `average` | Aggregation when grouping: `min`, `max`, `avg`, `sum`, `percentage` |
| `time_group` | `average` | Time aggregation: `min`, `max`, `avg`, `sum`, `median`, `stddev`, `percentile` |
| `format` | `json2` | Output: `json`, `json2`, `csv`, `tsv`, `prometheus`, `markdown` |
| `options` | `seconds,jsonwrap` | Flags: `nonzero`, `null2zero`, `absolute`, `percentage`, `raw`, `minify` |
| `dimensions` | `*` | Filter specific dimensions |
| `instances` | `*` | Filter specific instances |
| `nodes` | `*` | Filter specific nodes |
| `labels` | `*` | Filter by labels (`name:value` pattern) |
| `scope_contexts` | `*` | Limit scope (checked before `contexts` filter) |
| `timeout` | `0` | Query timeout in milliseconds |

Simple pattern syntax: `*` wildcard, space-separated OR, prefix with exclamation mark for negation. e.g. `disk.* \!disk.inodes`

### `/api/v3/alerts` — Current Alert Status

| Parameter | Default | Description |
|-----------|---------|-------------|
| `status` | — | Filter: `CRITICAL`, `WARNING`, `CLEAR`, `UNDEFINED`. CSV for multiple |
| `alert` | — | Alert name pattern. e.g. `ram_in_use`, `*cpu*` |
| `contexts` | `*` | Filter by metric context |
| `nodes` | `*` | Filter by node |
| `options` | — | `summary`, `values`, `instances`, `configurations` |
| `timeout` | `30000` | Query timeout (ms). Returns partial results on timeout |

### `/api/v3/alert_transitions` — Alert History

| Parameter | Default | Description |
|-----------|---------|-------------|
| `last` | `1` | Number of transition records to return (newest first) |
| `alert` | — | Filter by alert name |
| `contexts` | — | Filter by context. e.g. `system.cpu,system.ram` |
| `after` / `before` | — | Time range filter |
| `f_status` | — | Facet: `CRITICAL`, `WARNING`, `CLEAR`, `REMOVED` |
| `f_class` | — | Facet: `Errors`, `Latency`, `Utilization`, `Availability`, `Workload` |
| `f_component` | — | Facet: `Network`, `Disk`, `Memory`, `CPU`, `Database` |
| `f_type` | — | Facet: `System`, `Database`, `Web Server`, `Network`, `Storage` |
| `anchor_gi` | — | Pagination: `global_id` from last record of previous page |

### `/api/v3/weights` — Anomaly Scoring

Compares two time windows across all metrics. Returns weight 0.0 (different) to 1.0 (similar).

| Parameter | Default | Description |
|-----------|---------|-------------|
| `method` | — | `ks2` (Kolmogorov-Smirnov), `volume`, `anomaly-rate`, `value` |
| `after` / `before` | `-600` / `0` | Highlight (comparison) window |
| `baseline_after` / `baseline_before` | `-600` / `0` | Baseline window (auto-adjusts to power-of-two multiple) |
| `contexts` | `*` | Filter contexts |
| `points` | `500` | Detail level for statistical analysis |

### `/api/v3/contexts` — Discover Available Metrics

List all metric contexts. Use to discover what's being monitored.

| Parameter | Default | Description |
|-----------|---------|-------------|
| `contexts` | `*` | Filter pattern |
| `nodes` | `*` | Filter nodes |
| `options` | — | `instances`, `dimensions`, `labels`, `values`, `summary` |

### `/api/v3/function` — Execute Live Functions

Run named functions for live data (processes, services, connections).

| Parameter | Default | Description |
|-----------|---------|-------------|
| `function` | — (required) | Function name (case-sensitive, kebab-case) |
| `timeout` | `60` | Timeout in seconds (1–3600) |

Built-in functions: `processes`, `systemd-list-units`, `network-connections`, `mount-points`, `docker-containers`, `docker-images`, `apps-processes`, `ipmi-sensors`, `logs-query`

Use `GET /api/v3/functions` to discover available functions on the agent.

### `/api/v3/allmetrics` — Export Metrics

| Parameter | Default | Description |
|-----------|---------|-------------|
| `format` | `shell` | `shell` (bash vars), `json`, `prometheus`, `prometheus_all_hosts` |
| `filter` | — | Simple pattern for charts. e.g. `system.*` or `disk.* net.*` |

## Context Names

Common metric context names follow the pattern `<module>.<metric>`:

| Context | What it measures |
|---------|-----------------|
| `system.cpu` | CPU utilization (user, system, nice, iowait, etc.) |
| `system.ram` | RAM usage (used, cached, buffers, free) |
| `system.load` | System load averages (1, 5, 15 min) |
| `system.swap` | Swap usage |
| `system.io` | System-wide I/O |
| `system.net` | System-wide network traffic |
| `disk.io` | Per-disk I/O throughput |
| `disk.ops` | Per-disk operation counts |
| `disk.space` | Per-disk space usage |
| `disk.inodes` | Per-disk inode usage |
| `disk.await` | Per-disk average I/O latency |
| `disk.backlog` | Per-disk I/O backlog |
| `net.net` | Per-interface network traffic |
| `net.packets` | Per-interface packet counts |
| `net.drops` | Per-interface dropped packets |
| `net.errors` | Per-interface errors |
| `cgroup.cpu` | Container/cgroup CPU |
| `cgroup.mem` | Container/cgroup memory |

Discover all available contexts: `GET /api/v3/contexts`

## Optimization Recommendations Pattern

### High CPU
1. Query: `contexts=system.cpu&after=-900` — check overall usage
2. Query: `contexts=system.load&after=-900` — check load averages
3. Run: `function=processes` — identify top CPU consumers
4. Look for: sustained >80% usage, load > core count, iowait spikes
5. Recommend: identify runaway processes, check for CPU-bound workloads, consider scaling

### Memory Pressure
1. Query: `contexts=system.ram&after=-900` — check RAM breakdown
2. Query: `contexts=system.swap&after=-900` — check swap activity
3. Check alerts: `alert=ram_in_use` or `alert=used_swap`
4. Look for: low free+cached, active swap usage, OOM alerts
5. Recommend: identify memory-hungry processes, tune cache settings, add RAM or swap

### Disk Bottleneck
1. Query: `contexts=disk.io&after=-900` — check throughput
2. Query: `contexts=disk.await&after=-900` — check I/O latency
3. Query: `contexts=disk.backlog&after=-900` — check queue depth
4. Query: `contexts=disk.space&after=-900` — check free space
5. Look for: high await times, growing backlog, space >85%
6. Recommend: identify I/O-heavy processes, check for disk-bound workloads, clean disk space

### Network Issues
1. Query: `contexts=net.net&after=-900` — check bandwidth
2. Query: `contexts=net.drops&after=-900` — check packet drops
3. Query: `contexts=net.errors&after=-900` — check errors
4. Run: `function=network-connections` — check active connections
5. Look for: packet drops, errors, bandwidth saturation
6. Recommend: check for network-bound services, tune buffer sizes, investigate error sources

## Query Patterns

```bash
BASE="http://localhost:19999"

# Last 10 minutes of CPU usage
curl -s "$BASE/api/v3/data?contexts=system.cpu&after=-600&format=json2" | jq

# Last hour of disk space, grouped by instance
curl -s "$BASE/api/v3/data?contexts=disk.space&after=-3600&group_by=instance" | jq

# Active warnings and criticals
curl -s "$BASE/api/v3/alerts?status=WARNING,CRITICAL&options=summary,values" | jq

# Last 50 alert transitions
curl -s "$BASE/api/v3/alert_transitions?last=50" | jq

# Find anomalous metrics in last 5 minutes vs baseline
curl -s "$BASE/api/v3/weights?method=anomaly-rate&after=-300&before=0" | jq

# List running processes with resource usage
curl -s "$BASE/api/v3/function?function=processes" | jq

# Systemd service status
curl -s "$BASE/api/v3/function?function=systemd-list-units" | jq

# Export all metrics as JSON
curl -s "$BASE/api/v3/allmetrics?format=json" | jq

# Discover all available metric contexts
curl -s "$BASE/api/v3/contexts?options=summary" | jq

# Memory usage with specific dimensions, CSV output
curl -s "$BASE/api/v3/data?contexts=system.ram&dimensions=used,cached,free&after=-3600&format=csv"

# Compare two time windows (KS2 method) for correlation
curl -s "$BASE/api/v3/weights?method=ks2&after=-300&before=0&baseline_after=-3600&baseline_before=-300" | jq

# Per-disk I/O latency over last hour, non-zero only
curl -s "$BASE/api/v3/data?contexts=disk.await&after=-3600&group_by=instance&options=nonzero" | jq
```

## Full API Reference

See `netadata-oai.json` in this skill directory for the complete OpenAPI v3 specification (all endpoints, parameters, schemas, and response formats).
