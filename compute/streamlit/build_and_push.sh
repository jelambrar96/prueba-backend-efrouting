#!/bin/bash
set -euo pipefail

# Script: Build and Push Streamlit Docker image to ECR
# Usage: ./build_and_push.sh <aws_region> <ecr_repo_url> <image_tag>

AWS_REGION="${1:-us-east-1}"
ECR_REPO_URL="${2:-}"
IMAGE_TAG="${3:-latest}"
DOCKERFILE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Validate inputs
if [ -z "$ECR_REPO_URL" ]; then
    echo "❌ Error: ECR_REPO_URL is required"
    echo "Usage: $0 <aws_region> <ecr_repo_url> <image_tag>"
    exit 1
fi

# Extract ECR URI and repository name
ECR_URI=$(echo "$ECR_REPO_URL" | cut -d'/' -f1)
REPO_NAME=$(echo "$ECR_REPO_URL" | cut -d'/' -f2)
IMAGE_NAME="${REPO_NAME}:${IMAGE_TAG}"
FULL_IMAGE_URI="${ECR_REPO_URL}:${IMAGE_TAG}"

echo "🚀 Building and pushing Streamlit Docker image to ECR"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📍 AWS Region:        $AWS_REGION"
echo "📦 ECR Repository:    $ECR_REPO_URL"
echo "🏷️  Image Tag:         $IMAGE_TAG"
echo "📂 Dockerfile Dir:    $DOCKERFILE_DIR"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Step 1: Verify Docker is available
echo ""
echo "✓ Step 1: Checking Docker..."
if ! command -v docker &> /dev/null; then
    echo "❌ Error: Docker is not installed or not in PATH"
    exit 1
fi
DOCKER_VERSION=$(docker --version | cut -d' ' -f3 | cut -d',' -f1)
echo "✓ Docker version: $DOCKER_VERSION"

# Step 2: Verify AWS CLI
echo ""
echo "✓ Step 2: Checking AWS CLI..."
if ! command -v aws &> /dev/null; then
    echo "❌ Error: AWS CLI is not installed or not in PATH"
    exit 1
fi
AWS_VERSION=$(aws --version | cut -d' ' -f1 | cut -d'/' -f2)
echo "✓ AWS CLI version: $AWS_VERSION"

# Step 3: Verify Dockerfile exists
echo ""
echo "✓ Step 3: Checking Dockerfile..."
if [ ! -f "$DOCKERFILE_DIR/Dockerfile" ]; then
    echo "❌ Error: Dockerfile not found at $DOCKERFILE_DIR/Dockerfile"
    exit 1
fi
echo "✓ Dockerfile found"

# Step 4: Get AWS account ID
echo ""
echo "✓ Step 4: Getting AWS account ID..."
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
if [ -z "$ACCOUNT_ID" ]; then
    echo "❌ Error: Could not get AWS account ID. Check AWS credentials."
    exit 1
fi
echo "✓ AWS Account ID: $ACCOUNT_ID"

# Step 5: Login to ECR
echo ""
echo "✓ Step 5: Logging in to ECR..."
if ! aws ecr get-login-password --region "$AWS_REGION" | \
     docker login --username AWS --password-stdin "$ECR_URI"; then
    echo "❌ Error: Failed to login to ECR"
    exit 1
fi
echo "✓ ECR login successful"

# Step 6: Build Docker image
echo ""
echo "✓ Step 6: Building Docker image..."
echo "   Command: docker build -t $IMAGE_NAME -f $DOCKERFILE_DIR/Dockerfile $DOCKERFILE_DIR"
if ! docker build \
    -t "$IMAGE_NAME" \
    -f "$DOCKERFILE_DIR/Dockerfile" \
    "$DOCKERFILE_DIR"; then
    echo "❌ Error: Docker build failed"
    exit 1
fi
echo "✓ Docker image built successfully: $IMAGE_NAME"

# Step 7: Tag image with full ECR URI
echo ""
echo "✓ Step 7: Tagging image with ECR URI..."
echo "   Command: docker tag $IMAGE_NAME $FULL_IMAGE_URI"
if ! docker tag "$IMAGE_NAME" "$FULL_IMAGE_URI"; then
    echo "❌ Error: Failed to tag image"
    exit 1
fi
echo "✓ Image tagged: $FULL_IMAGE_URI"

# Step 8: Push image to ECR
echo ""
echo "✓ Step 8: Pushing image to ECR..."
echo "   Command: docker push $FULL_IMAGE_URI"
if ! docker push "$FULL_IMAGE_URI"; then
    echo "❌ Error: Failed to push image to ECR"
    exit 1
fi
echo "✓ Image pushed successfully"

# Step 9: Get image digest
echo ""
echo "✓ Step 9: Getting image digest..."
IMAGE_DIGEST=$(docker inspect --format='{{index .RepoDigests 0}}' "$FULL_IMAGE_URI" 2>/dev/null || echo "N/A")
echo "✓ Image Digest: $IMAGE_DIGEST"

# Step 10: Summary
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Build and push completed successfully!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📋 Summary:"
echo "  Repository:  $ECR_REPO_URL"
echo "  Image:       $IMAGE_NAME"
echo "  Full URI:    $FULL_IMAGE_URI"
echo "  Digest:      $IMAGE_DIGEST"
echo ""
echo "🚀 Ready to deploy to ECS Fargate!"
echo ""
