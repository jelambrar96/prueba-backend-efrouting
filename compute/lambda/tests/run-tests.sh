#!/bin/bash

# Script to run Lambda tests
# Usage: ./run-tests.sh [TEST_FILE] [VERBOSITY]

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )"
echo $SCRIPT_DIR
TEST_DIR="${SCRIPT_DIR}/tests"
TEST_FILE="${1:-test_app.py}"
VERBOSITY="${2:-2}"

echo "🧪 Running Lambda tests..."
echo ""
echo "Test directory: $TEST_DIR"
echo "Test file: $TEST_FILE"
echo ""

# Check if running from the lambda directory
if [ ! -d "$TEST_DIR" ]; then
    echo "❌ Error: Test directory not found at $TEST_DIR"
    echo "Run this script from the compute/lambda directory"
    exit 1
fi

# Run tests with unittest
cd "$SCRIPT_DIR"
python -m pytest "${TEST_DIR}/${TEST_FILE}" -v --tb=short 2>/dev/null || \
python -m unittest discover -s "${TEST_DIR}" -p "${TEST_FILE}" -v

echo ""
echo "✅ Tests completed!"
