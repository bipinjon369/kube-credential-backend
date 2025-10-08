#!/bin/bash

set -e

# Load environment variables
if [ -f .env ]; then
    export $(cat .env | grep -v '#' | xargs)
fi

# Check required variables
if [ -z "$AWS_REGION" ] || [ -z "$AWS_ACCOUNT_ID" ]; then
    echo "Error: AWS_REGION and AWS_ACCOUNT_ID must be set"
    exit 1
fi

SERVICE_NAME="verification-service"
ECR_REPO="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${SERVICE_NAME}"
IMAGE_TAG="latest"

echo "Building and pushing ${SERVICE_NAME} to ECR..."

# Copy shared folders
echo "Copying shared libraries..."
cp -r ../../shared/lib/* src/lib/
cp -r ../../shared/entities/* src/shared/

# Authenticate with ECR
echo "Authenticating with ECR..."
aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_REPO}

# Build Docker image
echo "Building Docker image..."
docker build -t ${SERVICE_NAME}:${IMAGE_TAG} .

# Tag for ECR
docker tag ${SERVICE_NAME}:${IMAGE_TAG} ${ECR_REPO}:${IMAGE_TAG}

# Push to ECR
echo "Pushing to ECR..."
docker push ${ECR_REPO}:${IMAGE_TAG}

echo "✅ Successfully pushed ${SERVICE_NAME}:${IMAGE_TAG} to ECR"
echo "📋 Next steps:"
echo "   1. Run ./scripts/deploy_ecs.sh to deploy to ECS"
echo "   2. Check ECS console for deployment status"