#!/bin/bash

# ============================================================================
# Start Spring Boot Application and OTel Collector
# ============================================================================
# This script:
#   1. Builds the Spring Boot application (if needed)
#   2. Starts the Spring Boot application in the background
#   3. Waits for the app to be ready
#   4. Starts the OTel Collector to scrape Prometheus metrics
# ============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}============================================================================${NC}"
echo -e "${BLUE}Spring Boot + OpenTelemetry Collector Startup${NC}"
echo -e "${BLUE}============================================================================${NC}"

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

# Build the application if JAR doesn't exist
if [ ! -f "target/rest-service-0.0.1-SNAPSHOT.jar" ]; then
    echo -e "${YELLOW}Building Spring Boot application...${NC}"
    ./mvnw clean package -DskipTests
fi

# Start Spring Boot application
echo -e "${GREEN}Starting Spring Boot application on port 8080...${NC}"
echo -e "${YELLOW}Passing Dynatrace configuration to application...${NC}"
java -jar target/rest-service-0.0.1-SNAPSHOT.jar \
    -DDT_ENDPOINT="$DT_ENDPOINT" \
    -DDT_API_TOKEN="$DT_API_TOKEN" &
APP_PID=$!

echo "Application PID: $APP_PID"

# Wait for application to be ready
echo -e "${YELLOW}Waiting for Spring Boot to start...${NC}"
MAX_WAIT=60
WAITED=0
while [ $WAITED -lt $MAX_WAIT ]; do
    if curl -s http://localhost:8080/actuator/health > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Spring Boot application is ready!${NC}"
        break
    fi
    sleep 2
    WAITED=$((WAITED + 2))
    echo -n "."
done
echo ""

if [ $WAITED -ge $MAX_WAIT ]; then
    echo -e "${RED}ERROR: Application failed to start within $MAX_WAIT seconds${NC}"
    kill $APP_PID 2>/dev/null || true
    exit 1
fi

# Verify Prometheus endpoint
echo -e "${YELLOW}Verifying Prometheus endpoint...${NC}"
if curl -s http://localhost:8080/actuator/prometheus | head -5; then
    echo -e "${GREEN}✓ Prometheus metrics endpoint is accessible${NC}"
else
    echo -e "${RED}ERROR: Cannot access Prometheus metrics endpoint${NC}"
    kill $APP_PID 2>/dev/null || true
    exit 1
fi

echo ""
echo -e "${BLUE}============================================================================${NC}"
echo -e "${GREEN}Spring Boot application is running${NC}"
echo -e "  Health: http://localhost:8080/actuator/health"
echo -e "  Metrics: http://localhost:8080/actuator/prometheus"
echo -e "  API endpoints:"
echo -e "    - http://localhost:8080/greeting?name=World"
echo -e "    - http://localhost:8080/sortear"
echo -e "    - http://localhost:8080/message?message=test&record_id=123"
echo -e "${BLUE}============================================================================${NC}"
echo ""

# Start OTel Collector
echo -e "${GREEN}Starting OpenTelemetry Collector...${NC}"
echo -e "${YELLOW}Press Ctrl+C to stop both application and collector${NC}"
echo ""

# Cleanup function
cleanup() {
    echo ""
    echo -e "${YELLOW}Stopping services...${NC}"
    kill $APP_PID 2>/dev/null || true
    echo -e "${GREEN}Services stopped${NC}"
    exit 0
}

trap cleanup SIGINT SIGTERM

# Start collector (this will run in foreground)
./start-otel-collector.sh
