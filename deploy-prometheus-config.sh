#!/bin/bash

# Deploy Prometheus configuration via Dynatrace API
# Replace YOUR_API_TOKEN and YOUR_ACTIVEGATE_ID with actual values

DYNATRACE_URL="https://zhy38306.live.dynatrace.com"
API_TOKEN="YOUR_API_TOKEN"  # Needs WriteConfig permission
ACTIVEGATE_ID="YOUR_ACTIVEGATE_ID"

# Get the application port (default 8080)
APP_PORT=8080

# Create the configuration
cat > prometheus-config.json <<EOF
{
  "value": {
    "enabled": true,
    "url": "http://localhost:${APP_PORT}/actuator/prometheus",
    "enabledActiveGates": ["${ACTIVEGATE_ID}"],
    "scrapeInterval": 60,
    "scrapeTimeout": 10,
    "label": "simple-java-rest-service",
    "metadata": {
      "configurationVersions": [1],
      "clusterVersion": "1.0.0"
    }
  }
}
EOF

# Deploy via API
curl -X POST "${DYNATRACE_URL}/api/config/v1/extensions/dynatrace.python.prometheus/instances" \
  -H "Authorization: Api-Token ${API_TOKEN}" \
  -H "Content-Type: application/json" \
  -d @prometheus-config.json

echo "Configuration deployed successfully"

# Clean up
rm prometheus-config.json
