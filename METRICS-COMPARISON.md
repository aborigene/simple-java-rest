# Dual Metrics Export: Prometheus Scraping vs Direct OTLP

This configuration provides **TWO ways** to send metrics to Dynatrace for comparison:

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    Spring Boot Application                      │
│                                                                 │
│  ┌──────────────────────┐      ┌──────────────────────────┐   │
│  │ Micrometer Registry  │      │ Micrometer Registry      │   │
│  │   (Prometheus)       │      │    (OTLP)                │   │
│  └──────────────────────┘      └──────────────────────────┘   │
│            │                              │                     │
└────────────┼──────────────────────────────┼─────────────────────┘
             │                              │
             │ Scrape                       │ Direct Push
             │ /actuator/prometheus         │ OTLP/HTTP
             │                              │
             ↓                              ↓
   ┌─────────────────────┐        ┌─────────────────────┐
   │ OTel Collector      │        │   Dynatrace         │
   │ (Prometheus Rcv)    │        │   OTLP Endpoint     │
   └─────────────────────┘        └─────────────────────┘
             │                              
             │ OTLP/HTTP                    
             │                              
             ↓                              
   ┌─────────────────────┐                  
   │   Dynatrace         │                  
   │   OTLP Endpoint     │                  
   └─────────────────────┘                  
```

## Two Metric Streams

### Stream 1: Prometheus Scraping (via OTel Collector)
- **Path**: App → Prometheus Endpoint → OTel Collector → Dynatrace
- **Metric Names**: Original names (e.g., `http_server_requests_seconds`)
- **Labels**: `application=rest-service`, `environment=production`, `service=java-rest-api`
- **Frequency**: 30 seconds (scrape interval)

### Stream 2: Direct OTLP Export
- **Path**: App → Dynatrace OTLP Endpoint (direct)
- **Metric Names**: With `_otlp` suffix (e.g., `http_server_requests_seconds_otlp`)
- **Labels**: `application=rest-service-otlp`, `environment=production`, `service=java-rest-api-otlp`
- **Frequency**: 30 seconds (export interval)

## Metric Name Comparison

| Metric Type | Prometheus Scraping | Direct OTLP |
|-------------|-------------------|-------------|
| HTTP Requests | `http_server_requests_seconds_bucket` | `http_server_requests_seconds_otlp_bucket` |
| Greeting API | `greeting_api_seconds_bucket` | `greeting_api_seconds_otlp_bucket` |
| Sortear API | `sortear_api_seconds_bucket` | `sortear_api_seconds_otlp_bucket` |
| Message API | `message_api_seconds_bucket` | `message_api_seconds_otlp_bucket` |
| JVM Memory | `jvm_memory_used_bytes` | `jvm_memory_used_bytes_otlp` |

## Configuration Files

### 1. pom.xml
Added dependencies:
- `micrometer-registry-prometheus` - For Prometheus endpoint
- `micrometer-registry-otlp` - For direct OTLP export

### 2. application.properties
```properties
# Prometheus endpoint (for OTel Collector scraping)
management.metrics.export.prometheus.enabled=true

# Direct OTLP export to Dynatrace
management.metrics.export.otlp.enabled=true
management.metrics.export.otlp.url=${DT_ENDPOINT}/v1/metrics
management.metrics.export.otlp.headers.Authorization=Api-Token ${DT_API_TOKEN}
```

### 3. MetricsConfig.java
Custom MeterFilter that adds `_otlp` suffix to metrics sent via OTLP registry:
```java
@Bean
public MeterRegistryCustomizer<OtlpMeterRegistry> otlpMetricNaming() {
    return registry -> registry.config()
        .meterFilter(new MeterFilter() {
            @Override
            public Meter.Id map(Meter.Id id) {
                return id.withName(id.getName() + "_otlp");
            }
        });
}
```

### 4. config.yaml (OTel Collector)
Prometheus receiver configuration:
```yaml
receivers:
  prometheus:
    config:
      scrape_configs:
        - job_name: 'spring-boot-app'
          scrape_interval: 30s
          metrics_path: '/actuator/prometheus'
          static_configs:
            - targets: ['localhost:8080']
```

## Setup and Running

### Prerequisites
```bash
# Set environment variables
export DT_API_TOKEN="your-api-token-here"
export DT_ENDPOINT="https://zhy38306.live.dynatrace.com/api/v2/otlp"
```

### Build Application
```bash
./mvnw clean package -DskipTests
```

### Option 1: Run Everything Together (Recommended)
```bash
chmod +x start-all.sh
./start-all.sh
```

This starts:
1. Spring Boot app (with both Prometheus endpoint AND direct OTLP export)
2. OTel Collector (scraping Prometheus endpoint)

### Option 2: Run Separately

**Terminal 1 - Spring Boot:**
```bash
chmod +x start-app-otlp.sh
./start-app-otlp.sh
```

**Terminal 2 - OTel Collector:**
```bash
./start-otel-collector.sh
```

## Verification

### 1. Check Prometheus Endpoint
```bash
curl http://localhost:8080/actuator/prometheus | head -30
```

Expected output:
```
# HELP http_server_requests_seconds  
# TYPE http_server_requests_seconds histogram
http_server_requests_seconds_bucket{method="GET",uri="/greeting",status="200",le="0.05"} 5.0
...
```

### 2. Generate Traffic
```bash
# Generate some test traffic
for i in {1..10}; do
  curl "http://localhost:8080/greeting?name=Test$i"
  curl "http://localhost:8080/sortear"
  curl "http://localhost:8080/message?message=hello&record_id=$i"
  sleep 1
done
```

### 3. Verify in Dynatrace

Wait 1-2 minutes, then check Dynatrace:

**Navigate to: Observe and explore → Metrics**

Search for **Prometheus-scraped metrics** (no suffix):
- `http_server_requests_seconds_bucket`
- `greeting_api_seconds_bucket`
- Filter by: `application=rest-service`

Search for **Direct OTLP metrics** (with _otlp suffix):
- `http_server_requests_seconds_otlp_bucket`
- `greeting_api_seconds_otlp_bucket`
- Filter by: `application=rest-service-otlp`

## Comparison Queries in Dynatrace

### Compare Response Time P95

```dql
// Prometheus-scraped metrics
timeseries p95_prometheus = percentile(http_server_requests_seconds_bucket, 95)
| filter application == "rest-service"
| fieldsAdd source = "Prometheus Scraping"

// Direct OTLP metrics
timeseries p95_otlp = percentile(http_server_requests_seconds_otlp_bucket, 95)
| filter application == "rest-service-otlp"
| fieldsAdd source = "Direct OTLP"
```

### Compare Request Counts

```dql
// Prometheus path
timeseries count_prometheus = sum(http_server_requests_seconds_count)
| filter application == "rest-service"

// OTLP path
timeseries count_otlp = sum(http_server_requests_seconds_otlp_count)
| filter application == "rest-service-otlp"
```

### Side-by-Side Comparison by Endpoint

```dql
timeseries 
  prom_greeting = percentile(greeting_api_seconds_bucket, 95),
  otlp_greeting = percentile(greeting_api_seconds_otlp_bucket, 95),
  by: {uri}
| filter application == "rest-service" or application == "rest-service-otlp"
```

## Expected Behavior

Both streams should show:
- **Similar values** (metrics represent the same data)
- **Similar timing** (both export every 30 seconds)
- **Same histogram buckets** (50ms, 100ms, 200ms, 300ms, 500ms, 1s, 2s, 5s)
- **Similar percentiles** (p50, p75, p95, p99)

### Potential Differences

You might observe slight differences:

1. **Timing offset**: Scraping happens at different times than direct export
2. **Aggregation**: Prometheus scraping captures point-in-time snapshot, OTLP is cumulative
3. **Cardinality**: Different label sets might affect aggregations
4. **Network latency**: Direct OTLP might arrive faster

## Troubleshooting

### Prometheus metrics appear, but not OTLP metrics

**Check application logs:**
```bash
# Look for OTLP export errors
tail -f /var/log/syslog | grep -i otlp
```

**Verify environment variables are passed:**
```bash
ps aux | grep java
# Should see -DDT_ENDPOINT and -DDT_API_TOKEN
```

**Test OTLP endpoint connectivity:**
```bash
curl -X POST "$DT_ENDPOINT/v1/metrics" \
  -H "Authorization: Api-Token $DT_API_TOKEN" \
  -H "Content-Type: application/x-protobuf" \
  -v
```

### OTLP metrics appear, but not Prometheus metrics

**Check OTel Collector logs:**
```bash
# Look for scrape errors or connection refused
journalctl -u otelcol-contrib -f
```

**Verify Prometheus endpoint is accessible:**
```bash
curl http://localhost:8080/actuator/prometheus
```

### Metrics have different values

This is expected to some degree:
- **Prometheus scraping**: Pull-based, captures state at scrape time
- **OTLP export**: Push-based, cumulative over export interval

For accurate comparison, use rate() or increase() functions.

### High cardinality warning

If you see too many metrics:

**Filter specific metrics in application.properties:**
```properties
management.metrics.export.otlp.enabled=true
# Only export specific metrics
management.metrics.export.otlp.metric-patterns=http_server_requests_seconds,greeting_api_seconds,sortear_api_seconds,message_api_seconds
```

## Cost and Performance Considerations

### Data Volume
- **Double metrics volume**: You're sending metrics via two paths
- **Recommendation**: Use for comparison only, not production long-term
- **To reduce**: Disable one path after comparison

### Disable Prometheus Scraping (keep only OTLP):
```yaml
# In config.yaml, remove prometheus from receivers list
receivers: [hostmetrics/1m, hostmetrics/5m, hostmetrics/1h]
```

### Disable Direct OTLP (keep only Prometheus):
```properties
# In application.properties
management.metrics.export.otlp.enabled=false
```

### Network and CPU
- Each export path consumes bandwidth and CPU
- OTel Collector adds processing overhead
- Direct OTLP is more efficient (fewer hops)

## Recommendations

### For Testing/Comparison
✅ Run both paths simultaneously
✅ Use _otlp suffix for clear distinction
✅ Compare metrics over 1-hour period
✅ Validate percentiles match within tolerance

### For Production
Choose ONE path based on your needs:

**Use Prometheus Scraping when:**
- You have existing Prometheus infrastructure
- You want centralized metric collection
- You need to add processing/filtering
- You have multiple services to scrape

**Use Direct OTLP when:**
- You want minimal latency
- You prefer push-based metrics
- You want to reduce infrastructure complexity
- You need real-time metrics export

## Next Steps

1. **Run comparison for 1 hour**
2. **Analyze metric accuracy** in Dynatrace dashboards
3. **Compare data volume** (Settings → Usage & cost)
4. **Measure latency** (time to appear in Dynatrace)
5. **Choose one approach** for production
6. **Create alerts** based on chosen metrics
7. **Build dashboards** for monitoring

## Clean Up

To stop both services:
```bash
# If using start-all.sh, just press Ctrl+C

# Manual cleanup
pkill -f "rest-service-0.0.1-SNAPSHOT.jar"
pkill -f "otelcol-contrib"
```

## References

- [Micrometer OTLP Registry](https://micrometer.io/docs/registry/otlp)
- [Dynatrace OTLP Ingestion](https://www.dynatrace.com/support/help/extend-dynatrace/opentelemetry)
- [OpenTelemetry Prometheus Receiver](https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/main/receiver/prometheusreceiver)
