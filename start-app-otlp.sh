#!/bin/bash

# ============================================================================
# Start Spring Boot with Direct OTLP Export
# ============================================================================
# This script starts Spring Boot with OTLP metrics export enabled.
# The application will send metrics directly to Dynatrace while also
# exposing Prometheus endpoint for OTel Collector scraping.
#
# Two metric streams:
#   1. Direct OTLP → Dynatrace (metrics with _otlp suffix)
#   2. Prometheus → OTel Collector → Dynatrace (original metric names)
# ============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "============================================================================"
echo "Starting Spring Boot with Direct OTLP Export"
echo "============================================================================"

# Check environment variables
if [ -z "$DT_API_TOKEN" ]; then
    echo -e "${RED}ERROR: DT_API_TOKEN environment variable is not set${NC}"
    echo "Please run: export DT_API_TOKEN='your-api-token'"
    exit 1
fi

# Set default endpoint
if [ -z "$DT_ENDPOINT" ]; then
    export DT_ENDPOINT="https://zhy38306.live.dynatrace.com/api/v2/otlp"
    echo -e "${YELLOW}Using default Dynatrace endpoint: $DT_ENDPOINT${NC}"
fi

# Build if needed
if [ ! -f "target/rest-service-0.0.1-SNAPSHOT.jar" ]; then
    echo -e "${YELLOW}Building Spring Boot application...${NC}"
    ./mvnw clean package -DskipTests
fi

echo ""
echo -e "${GREEN}Starting Spring Boot with:${NC}"
echo "  - Direct OTLP export to: $DT_ENDPOINT/v1/metrics"
echo "  - Prometheus endpoint at: http://localhost:8080/actuator/prometheus"
echo "  - Metrics with _otlp suffix for OTLP-exported metrics"
echo ""

# Start with environment variables passed as system properties
java -jar target/rest-service-0.0.1-SNAPSHOT.jar \
    -DDT_ENDPOINT="$DT_ENDPOINT" \
    -DDT_API_TOKEN="$DT_API_TOKEN"
