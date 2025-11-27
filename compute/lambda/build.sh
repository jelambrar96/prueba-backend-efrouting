#!/bin/bash

# Build script for Lambda deployment package
# Uses Docker to ensure consistent Python environment and writes files with host UID/GID

set -euo pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
BUILD_DIR="${SCRIPT_DIR}/build"
PACKAGE_DIR="${SCRIPT_DIR}/build/package"
LAMBDA_ZIP="${SCRIPT_DIR}/lambda.zip"

echo "🔨 Building Lambda deployment package..."

# Clean previous build
rm -rf "$BUILD_DIR" "$LAMBDA_ZIP"
mkdir -p "$PACKAGE_DIR"

# Helper: ensure host uid/gid available
HOST_UID=${HOST_UID:-$(id -u)}
HOST_GID=${HOST_GID:-$(id -g)}

# Install dependencies using Docker if available
if command -v docker &> /dev/null; then
    echo "📦 Installing dependencies using Docker (writing as UID:$HOST_UID GID:$HOST_GID)..."

    # Bind mount the package dir so files are created on the host
    docker run --rm \
        -u "$HOST_UID:$HOST_GID" \
        -v "$PACKAGE_DIR":/var/task/package:rw \
        -v "$SCRIPT_DIR":/var/task:ro \
        --entrypoint /bin/sh \
        public.ecr.aws/lambda/python:3.12 \
        -lc 'pip install --no-cache-dir -r /var/task/requirements.txt -t /var/task/package && cp /var/task/app.py /var/task/package/ 2>/dev/null || true && [ -f /var/task/model.py ] && cp /var/task/model.py /var/task/package/ || true'

else
    echo "⚠️  Docker not found. Falling back to local pip (must be run as non-root to avoid root-owned files)..."
    
    if command -v pip3 &> /dev/null; then
        pip3 install --no-cache-dir -r "$SCRIPT_DIR/requirements.txt" -t "$PACKAGE_DIR"
    
    elif command -v pip &> /dev/null; then
        pip install --no-cache-dir -r "$SCRIPT_DIR/requirements.txt" -t "$PACKAGE_DIR"
    
    else
        echo "❌ pip not found. Cannot install dependencies. Exiting."
        exit 1
    fi

    # Copy lambda files
    cp "$SCRIPT_DIR/app.py" "$PACKAGE_DIR/"
    [ -f "$SCRIPT_DIR/model.py" ] && cp "$SCRIPT_DIR/model.py" "$PACKAGE_DIR/" || true
fi

# Ensure permissions are writable by the host user
chmod -R u+rwX "$BUILD_DIR"

# Clean up unnecessary files
echo "🧹 Cleaning up unnecessary files in package..."
find "$PACKAGE_DIR" -type d -name "*.dist-info" -exec rm -rf {} + 2>/dev/null || true
find "$PACKAGE_DIR" -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
find "$PACKAGE_DIR" -type f -name "*.pyc" -delete 2>/dev/null || true

# Create zip file
echo "📦 Creating deployment package..."
cd "$PACKAGE_DIR"
zip -r "$LAMBDA_ZIP" .
cd "$SCRIPT_DIR"

echo "✅ Deployment package created successfully: $LAMBDA_ZIP"
PACKAGE_SIZE=$(du -h "$LAMBDA_ZIP" | cut -f1)
echo "📊 Package size: $PACKAGE_SIZE"

echo "..."
