#!/bin/bash

# Build script for Lambda deployment package
# Installs dependencies from requirements.txt and creates a zip file

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
BUILD_DIR="${SCRIPT_DIR}/build"
PACKAGE_DIR="${BUILD_DIR}/package"

echo "🔨 Building Lambda deployment package..."

# Create build directories
rm -rf "$BUILD_DIR"
mkdir -p "$PACKAGE_DIR"

# Install dependencies
echo "📦 Installing dependencies from requirements.txt..."
pip install -r "$SCRIPT_DIR/requirements.txt" -t "$PACKAGE_DIR"

# Copy Lambda functions
echo "📋 Copying Lambda code..."
cp "$SCRIPT_DIR/app.py" "$PACKAGE_DIR/"
cp "$SCRIPT_DIR/model.py" "$PACKAGE_DIR/"

# Create zip file
echo "📦 Creating deployment package..."
cd "$PACKAGE_DIR"
zip -r "$SCRIPT_DIR/lambda.zip" .
cd "$SCRIPT_DIR"

echo "✅ Deployment package created successfully: lambda.zip"
echo "📊 Package size: $(du -h lambda.zip | cut -f1)"
