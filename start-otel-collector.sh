#!/bin/bash

# ============================================================================
# OpenTelemetry Collector Startup Script
# ============================================================================
# This script starts the OTel Collector with the configured Prometheus scraper
# for Spring Boot actuator metrics.
#
# Prerequisites:
#   1. OpenTelemetry Collector installed
#   2. Spring Boot application running on localhost:8080
#   3. Dynatrace API token with metrics ingest permissions
# ============================================================================

# Check if environment variables are set
if [ -z "$DT_API_TOKEN" ]; then
    echo "ERROR: DT_API_TOKEN environment variable is not set"
    echo "Please run: export DT_API_TOKEN='your-api-token'"
    exit 1
fi

# Set default endpoint if not provided
if [ -z "$DT_ENDPOINT" ]; then
    export DT_ENDPOINT="https://zhy38306.live.dynatrace.com/api/v2/otlp"
    echo "Using default Dynatrace endpoint: $DT_ENDPOINT"
fi

# Set default memory threshold if not provided
if [ -z "$PROCESS_MEMORY_THRESHOLD_BYTES" ]; then
    export PROCESS_MEMORY_THRESHOLD_BYTES=52428800
    echo "Using default process memory threshold: 50MB"
fi

echo "============================================================================"
echo "Starting OpenTelemetry Collector"
echo "============================================================================"
echo "Configuration file: config.yaml"
echo "Dynatrace endpoint: $DT_ENDPOINT"
echo "Prometheus scrape target: localhost:8080/actuator/prometheus"
echo "Scrape interval: 30 seconds"
echo "============================================================================"

# Check if collector binary exists
if ! command -v otelcol-contrib &> /dev/null; then
    echo "ERROR: otelcol-contrib binary not found"
    echo ""
    echo "To install OpenTelemetry Collector Contrib:"
    echo "  wget https://github.com/open-telemetry/opentelemetry-collector-releases/releases/download/v0.95.0/otelcol-contrib_0.95.0_linux_amd64.tar.gz"
    echo "  tar -xvf otelcol-contrib_0.95.0_linux_amd64.tar.gz"
    echo "  sudo mv otelcol-contrib /usr/local/bin/"
    echo ""
    exit 1
fi

# Start the collector
otelcol-contrib --config=config.yaml
