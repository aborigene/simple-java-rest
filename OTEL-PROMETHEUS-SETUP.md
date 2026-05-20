# OpenTelemetry Collector + Prometheus Metrics to Dynatrace

This configuration enables the OpenTelemetry Collector to scrape Prometheus metrics from your Spring Boot application and send them to Dynatrace.

## Architecture

```
Spring Boot App (localhost:8080)
    |
    | /actuator/prometheus endpoint
    ↓
OTel Collector (Prometheus Receiver)
    |
    | OTLP HTTP
    ↓
Dynatrace (API v2 OTLP endpoint)
```

## Files Modified/Created

### Modified Files
- **config.yaml** - Added Prometheus receiver to scrape Spring Boot metrics
  - Scrapes `localhost:8080/actuator/prometheus` every 30 seconds
  - Added labels: application, environment, service
  - Integrated into existing metrics pipeline

### Created Files
- **start-otel-collector.sh** - Script to start the OTel Collector
- **start-all.sh** - Script to start both Spring Boot app and OTel Collector

## Configuration Details

### Prometheus Receiver Configuration
```yaml
receivers:
  prometheus:
    config:
      scrape_configs:
        - job_name: 'spring-boot-app'
          scrape_interval: 30s
          scrape_timeout: 10s
          metrics_path: '/actuator/prometheus'
          static_configs:
            - targets: ['localhost:8080']
              labels:
                application: 'rest-service'
                environment: 'production'
                service: 'java-rest-api'
```

### Metrics Collected

The OTel Collector will scrape and forward these histogram metrics to Dynatrace:

1. **HTTP Server Request Metrics**
   - `http_server_requests_seconds_bucket{le="..."}` - Request duration buckets
   - `http_server_requests_seconds_count` - Total request count
   - `http_server_requests_seconds_sum` - Total request duration
   - Tags: method, uri, status, exception

2. **Endpoint-Specific Metrics**
   - `greeting_api_seconds_bucket{le="..."}` - /greeting endpoint timing
   - `sortear_api_seconds_bucket{le="..."}` - /sortear endpoint timing
   - `message_api_seconds_bucket{le="..."}` - /message endpoint timing

3. **Histogram Buckets** (configured SLOs)
   - 50ms, 100ms, 200ms, 300ms, 500ms, 1s, 2s, 5s
   - Percentiles: p50, p75, p95, p99

4. **Additional Spring Boot Metrics**
   - JVM memory, threads, GC
   - System CPU, memory
   - Process metrics

## Setup Instructions

### 1. Install OpenTelemetry Collector (if not already installed)

```bash
# Download OTel Collector Contrib (includes Prometheus receiver)
wget https://github.com/open-telemetry/opentelemetry-collector-releases/releases/download/v0.95.0/otelcol-contrib_0.95.0_linux_amd64.tar.gz

# Extract
tar -xvf otelcol-contrib_0.95.0_linux_amd64.tar.gz

# Move to system path
sudo mv otelcol-contrib /usr/local/bin/

# Verify installation
otelcol-contrib --version
```

### 2. Set Environment Variables

```bash
# Required: Your Dynatrace API token (needs metrics ingest permission)
export DT_API_TOKEN="dt0c01.YOUR_API_TOKEN_HERE"

# Optional: Override default endpoint (already set to your tenant)
export DT_ENDPOINT="https://zhy38306.live.dynatrace.com/api/v2/otlp"

# Optional: Process memory threshold (default: 50MB)
export PROCESS_MEMORY_THRESHOLD_BYTES=52428800
```

### 3. Build the Spring Boot Application

```bash
./mvnw clean package -DskipTests
```

### 4. Start Everything

**Option A: Start Both Services (Recommended)**
```bash
chmod +x start-all.sh start-otel-collector.sh
./start-all.sh
```

This script:
- Builds the app (if needed)
- Starts Spring Boot on port 8080
- Waits for app to be ready
- Verifies Prometheus endpoint
- Starts OTel Collector
- Press Ctrl+C to stop both

**Option B: Start Manually**

Terminal 1 - Spring Boot:
```bash
java -jar target/rest-service-0.0.1-SNAPSHOT.jar
```

Terminal 2 - OTel Collector:
```bash
chmod +x start-otel-collector.sh
./start-otel-collector.sh
```

### 5. Verify Everything is Working

**Check Spring Boot Prometheus endpoint:**
```bash
curl http://localhost:8080/actuator/prometheus | grep http_server_requests
```

**Check OTel Collector health:**
```bash
curl http://localhost:13133/
```

**Generate some traffic:**
```bash
# Test endpoints to generate metrics
curl "http://localhost:8080/greeting?name=Test"
curl "http://localhost:8080/sortear"
curl "http://localhost:8080/message?message=hello&record_id=123"
```

**Check OTel Collector logs:**
Look for successful scrapes and exports:
```
Scrape successful (job=spring-boot-app)
Exporting metrics to Dynatrace
```

## Viewing Metrics in Dynatrace

### 1. Metrics Browser
Navigate to: **Observe and explore → Metrics**

Search for:
- `http_server_requests_seconds_bucket`
- `greeting_api_seconds_bucket`
- `sortear_api_seconds_bucket`
- `message_api_seconds_bucket`

### 2. Create Dashboard

Example DQL queries:

**Response Time Percentiles:**
```dql
timeseries p50 = percentile(http_server_requests_seconds_bucket, 50),
           p95 = percentile(http_server_requests_seconds_bucket, 95),
           p99 = percentile(http_server_requests_seconds_bucket, 99),
by: {uri, method}
```

**Request Rate:**
```dql
timeseries rate = rate(http_server_requests_seconds_count),
by: {uri, method, status}
```

**Endpoint-Specific Latency:**
```dql
timeseries greeting_p95 = percentile(greeting_api_seconds_bucket, 95),
           sortear_p95 = percentile(sortear_api_seconds_bucket, 95),
           message_p95 = percentile(message_api_seconds_bucket, 95)
```

### 3. Data Explorer
Navigate to: **Observe and explore → Data explorer**
- Select metric: `http_server_requests_seconds`
- Split by: `uri`, `method`, `status`
- Aggregation: p95, p99

## Troubleshooting

### Metrics not appearing in Dynatrace

1. **Check API token permissions:**
   - Token needs `metrics.ingest` scope
   - Verify at: Settings → Access tokens

2. **Check OTel Collector logs:**
   - Look for "connection refused" or "401 Unauthorized"
   - Verify DT_ENDPOINT and DT_API_TOKEN are set correctly

3. **Verify Spring Boot endpoint:**
   ```bash
   curl http://localhost:8080/actuator/prometheus
   ```

4. **Check network connectivity:**
   ```bash
   curl -H "Authorization: Api-Token $DT_API_TOKEN" \
        "$DT_ENDPOINT/v1/metrics"
   ```

### Collector not starting

1. **Check if port 8080 is available:**
   ```bash
   netstat -tuln | grep 8080
   ```

2. **Verify config syntax:**
   ```bash
   otelcol-contrib --config=config.yaml --dry-run
   ```

### High cardinality warnings

If you see too many metric dimensions in Dynatrace:

1. Add metric filtering to config.yaml:
   ```yaml
   processors:
     filter/prometheus:
       metrics:
         include:
           match_type: regexp
           metric_names:
             - http_server_requests_seconds.*
             - greeting_api_seconds.*
             - sortear_api_seconds.*
             - message_api_seconds.*
             - jvm_memory.*
   ```

2. Add to service pipeline:
   ```yaml
   metrics:
     receivers: [prometheus, ...]
     processors: [filter/prometheus, filter, ...]
   ```

## Customization

### Change scrape interval
Edit `config.yaml`:
```yaml
scrape_interval: 60s  # Change from 30s to 60s
```

### Add more labels
Edit `config.yaml`:
```yaml
labels:
  application: 'rest-service'
  environment: 'production'
  team: 'platform'
  version: '1.0.0'
```

### Scrape multiple endpoints
Add more targets in `config.yaml`:
```yaml
static_configs:
  - targets: ['localhost:8080', 'localhost:8081']
```

## Performance Considerations

- **Scrape interval**: 30s balances freshness vs. overhead
- **Metric cardinality**: Monitor DQL query performance
- **Collector resources**: ~50-100MB RAM typical
- **Network**: ~10-50KB per scrape depending on metrics
- **Batch size**: 3000 metrics per batch (configured)

## Security

- API tokens stored in environment variables only (not in config files)
- No metrics data cached on disk by default
- TLS enabled for Dynatrace communication
- Health check endpoint exposed on localhost:13133

## Next Steps

1. **Create Alerts**
   - High response time (p95 > threshold)
   - Error rate increase
   - Request rate anomalies

2. **Build Dashboards**
   - SLO dashboard with request/error/duration
   - Service health overview
   - Endpoint comparison

3. **Integrate with other services**
   - Add more Spring Boot apps
   - Scrape databases, message queues
   - Collect custom business metrics
