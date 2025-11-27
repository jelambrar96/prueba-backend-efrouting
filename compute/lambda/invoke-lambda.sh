#!/bin/bash

# Script to easily invoke the Lambda function manually
# Usage: ./invoke-lambda.sh [API_ENDPOINT] [OPTIONAL_PARAMS]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Get API endpoint from Terraform output or parameter
if [ -z "$1" ]; then
    echo -e "${YELLOW}No API endpoint provided. Trying to get from Terraform output...${NC}"
    cd "$(dirname "$0")/../../terraform"
    API_ENDPOINT=$(terraform output -raw api_gateway_endpoint 2>/dev/null || echo "")
    
    if [ -z "$API_ENDPOINT" ]; then
        echo -e "${RED}Error: Could not find API endpoint.${NC}"
        echo "Usage: ./invoke-lambda.sh <API_ENDPOINT> [OPTIONAL_JSON_PARAMS]"
        echo ""
        echo "Examples:"
        echo "  ./invoke-lambda.sh https://abc123.execute-api.us-east-1.amazonaws.com/invoke"
        echo "  ./invoke-lambda.sh https://abc123.execute-api.us-east-1.amazonaws.com/invoke '{\"offset_seconds\": 86400}'"
        exit 1
    fi
    echo -e "${GREEN}Found API endpoint: $API_ENDPOINT${NC}"
else
    API_ENDPOINT="$1"
fi

# Prepare request body
if [ -z "$2" ]; then
    echo -e "${YELLOW}No parameters provided. Using default (last 6 hours)...${NC}"
    PAYLOAD='{}'
else
    PAYLOAD="$2"
fi

echo -e "${YELLOW}Invoking Lambda...${NC}"
echo "Endpoint: $API_ENDPOINT"
echo "Payload: $PAYLOAD"
echo ""

# Make the request
RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$API_ENDPOINT" \
    -H "Content-Type: application/json" \
    -d "$PAYLOAD")

# Extract HTTP status code
HTTP_CODE=$(echo "$RESPONSE" | tail -n 1)
BODY=$(echo "$RESPONSE" | head -n -1)

# Pretty print JSON
echo "Response:"
echo "$BODY" | jq '.' 2>/dev/null || echo "$BODY"

# Check status
echo ""
if [ "$HTTP_CODE" = "200" ]; then
    echo -e "${GREEN}✓ Lambda invoked successfully (HTTP $HTTP_CODE)${NC}"
else
    echo -e "${RED}✗ Lambda invocation failed (HTTP $HTTP_CODE)${NC}"
    exit 1
fi
