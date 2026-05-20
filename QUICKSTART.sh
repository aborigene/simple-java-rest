#!/bin/bash
# Quick Setup - Dual Metrics Export (Prometheus + Direct OTLP)

# ============================================================================
# STEP 1: Set your Dynatrace API token
# ============================================================================
export DT_API_TOKEN="YOUR_API_TOKEN_HERE"
export DT_ENDPOINT="https://zhy38306.live.dynatrace.com/api/v2/otlp"

# ============================================================================
# STEP 2: Install OTel Collector (if not installed)
# ============================================================================
# wget https://github.com/open-telemetry/opentelemetry-collector-releases/releases/download/v0.95.0/otelcol-contrib_0.95.0_linux_amd64.tar.gz
# tar -xvf otelcol-contrib_0.95.0_linux_amd64.tar.gz
# sudo mv otelcol-contrib /usr/local/bin/

# ============================================================================
# STEP 3: Build the application
# ============================================================================
./mvnw clean package -DskipTests

# ============================================================================
# STEP 4: Make scripts executable
# ============================================================================
chmod +x start-otel-collector.sh start-all.sh start-app-otlp.sh test-metrics.sh

# ============================================================================
# STEP 5: Start everything (Spring Boot + OTel Collector)
# ============================================================================
# This starts BOTH metric export paths:
#   1. Prometheus scraping (OTel Collector → Dynatrace)
#   2. Direct OTLP (App → Dynatrace)
./start-all.sh

# ============================================================================
# STEP 6: Test the setup (run in another terminal)
# ============================================================================
# ./test-metrics.sh

# ============================================================================
# View metrics in Dynatrace
# ============================================================================
# Navigate to: Observe and explore → Metrics
# 
# Prometheus-scraped metrics (no suffix):
#   - http_server_requests_seconds_bucket
#   - greeting_api_seconds_bucket
#   - Filter: application=rest-service
#
# Direct OTLP metrics (with _otlp suffix):
#   - http_server_requests_seconds_otlp_bucket
#   - greeting_api_seconds_otlp_bucket
#   - Filter: application=rest-service-otlp

# ============================================================================
# Alternative: Start only Spring Boot with OTLP (no collector)
# ============================================================================
# ./start-app-otlp.sh
