#!/bin/bash

# ============================================================================
# Test Both Metric Paths
# ============================================================================
# This script verifies that both metric export paths are working:
#   1. Prometheus endpoint (for OTel Collector scraping)
#   2. Direct OTLP export to Dynatrace
# ============================================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}============================================================================${NC}"
echo -e "${BLUE}Testing Dual Metrics Export Setup${NC}"
echo -e "${BLUE}============================================================================${NC}"
echo ""

# Test 1: Check if Spring Boot is running
echo -e "${YELLOW}[1/6] Checking if Spring Boot is running...${NC}"
if curl -s http://localhost:8080/actuator/health > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Spring Boot is running${NC}"
else
    echo -e "${RED}✗ Spring Boot is not running${NC}"
    echo "Please start it with: ./start-all.sh or ./start-app-otlp.sh"
    exit 1
fi
echo ""

# Test 2: Check Prometheus endpoint
echo -e "${YELLOW}[2/6] Checking Prometheus endpoint...${NC}"
PROM_METRICS=$(curl -s http://localhost:8080/actuator/prometheus)
if echo "$PROM_METRICS" | grep -q "http_server_requests_seconds_bucket"; then
    echo -e "${GREEN}✓ Prometheus endpoint is working${NC}"
    echo "Sample metrics:"
    echo "$PROM_METRICS" | grep "http_server_requests_seconds_bucket" | head -3
else
    echo -e "${RED}✗ Prometheus endpoint not returning expected metrics${NC}"
fi
echo ""

# Test 3: Generate test traffic
echo -e "${YELLOW}[3/6] Generating test traffic...${NC}"
echo "Making 10 requests to each endpoint..."
for i in {1..10}; do
    curl -s "http://localhost:8080/greeting?name=Test$i" > /dev/null
    curl -s "http://localhost:8080/sortear" > /dev/null
    curl -s "http://localhost:8080/message?message=hello&record_id=$i" > /dev/null
    echo -n "."
done
echo ""
echo -e "${GREEN}✓ Generated 30 requests total${NC}"
echo ""

# Test 4: Verify metrics are being recorded
echo -e "${YELLOW}[4/6] Verifying metrics are being recorded...${NC}"
sleep 2  # Wait for metrics to be recorded
PROM_METRICS_AFTER=$(curl -s http://localhost:8080/actuator/prometheus)

if echo "$PROM_METRICS_AFTER" | grep -q "greeting_api_seconds_count"; then
    GREETING_COUNT=$(echo "$PROM_METRICS_AFTER" | grep "greeting_api_seconds_count" | grep -oP '\d+\.\d+' | head -1)
    echo -e "${GREEN}✓ Greeting API metrics recorded: $GREETING_COUNT requests${NC}"
else
    echo -e "${YELLOW}⚠ Greeting API metrics not found yet${NC}"
fi

if echo "$PROM_METRICS_AFTER" | grep -q "http_server_requests_seconds_count"; then
    HTTP_COUNT=$(echo "$PROM_METRICS_AFTER" | grep "http_server_requests_seconds_count" | grep 'uri="/greeting"' | grep -oP '\d+\.\d+' | head -1)
    echo -e "${GREEN}✓ HTTP server metrics recorded: $HTTP_COUNT requests to /greeting${NC}"
else
    echo -e "${YELLOW}⚠ HTTP server metrics not found yet${NC}"
fi
echo ""

# Test 5: Check if OTel Collector is running
echo -e "${YELLOW}[5/6] Checking if OTel Collector is running...${NC}"
if curl -s http://localhost:13133/ > /dev/null 2>&1; then
    echo -e "${GREEN}✓ OTel Collector health check is responding${NC}"
    echo "Prometheus scraping should be active"
else
    echo -e "${YELLOW}⚠ OTel Collector health check not responding${NC}"
    echo "Prometheus scraping may not be active"
    echo "Start OTel Collector separately if not using start-all.sh"
fi
echo ""

# Test 6: Check Dynatrace connectivity
echo -e "${YELLOW}[6/6] Checking Dynatrace connectivity...${NC}"
if [ -z "$DT_API_TOKEN" ] || [ -z "$DT_ENDPOINT" ]; then
    echo -e "${RED}✗ DT_API_TOKEN or DT_ENDPOINT not set${NC}"
    echo "Direct OTLP export may not be working"
    echo "Set with: export DT_API_TOKEN='your-token' DT_ENDPOINT='https://zhy38306.live.dynatrace.com/api/v2/otlp'"
else
    echo -e "${GREEN}✓ Environment variables are set${NC}"
    echo "  DT_ENDPOINT: $DT_ENDPOINT"
    echo "  DT_API_TOKEN: ${DT_API_TOKEN:0:20}..."
    
    # Test OTLP endpoint connectivity
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
        -X POST "$DT_ENDPOINT/v1/metrics" \
        -H "Authorization: Api-Token $DT_API_TOKEN" \
        -H "Content-Type: application/x-protobuf")
    
    if [ "$HTTP_CODE" == "200" ] || [ "$HTTP_CODE" == "400" ]; then
        echo -e "${GREEN}✓ Dynatrace OTLP endpoint is reachable (HTTP $HTTP_CODE)${NC}"
        echo "Direct OTLP export should be working"
    else
        echo -e "${RED}✗ Dynatrace OTLP endpoint returned HTTP $HTTP_CODE${NC}"
        echo "Check your API token permissions (needs metrics.ingest)"
    fi
fi
echo ""

# Summary
echo -e "${BLUE}============================================================================${NC}"
echo -e "${BLUE}Summary${NC}"
echo -e "${BLUE}============================================================================${NC}"
echo ""
echo "Metric Export Paths:"
echo ""
echo "1. ${GREEN}Prometheus Scraping${NC} (via OTel Collector)"
echo "   Spring Boot → /actuator/prometheus → OTel Collector → Dynatrace"
echo "   Metric names: http_server_requests_seconds_bucket, greeting_api_seconds_bucket, etc."
echo "   Labels: application=rest-service"
echo ""
echo "2. ${GREEN}Direct OTLP Export${NC}"
echo "   Spring Boot → Dynatrace OTLP Endpoint"
echo "   Metric names: http_server_requests_seconds_otlp_bucket, greeting_api_seconds_otlp_bucket, etc."
echo "   Labels: application=rest-service-otlp"
echo ""
echo "Wait 1-2 minutes, then check Dynatrace:"
echo ""
echo -e "${YELLOW}Observe and explore → Metrics${NC}"
echo ""
echo "Search for:"
echo "  - http_server_requests_seconds_bucket (Prometheus path)"
echo "  - http_server_requests_seconds_otlp_bucket (OTLP path)"
echo ""
echo "Filter by:"
echo "  - application=rest-service (Prometheus)"
echo "  - application=rest-service-otlp (Direct OTLP)"
echo ""
echo -e "${GREEN}Test complete!${NC}"
