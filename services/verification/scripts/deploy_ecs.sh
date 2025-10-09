#!/bin/bash

set -e

# Default region if not set
AWS_REGION=${AWS_REGION:-us-east-1}

# Configuration
SERVICE_NAME="kube-credential-backend-verification"
CLUSTER_NAME="kube-credential-backend-cluster"

echo "🚀 Deploying ${SERVICE_NAME} to ECS..."
echo "Region: $AWS_REGION"

# Check if service exists
echo "🔍 Checking if ECS service exists..."
aws ecs describe-services \
  --cluster "$CLUSTER_NAME" \
  --services "$SERVICE_NAME" \
  --region "$AWS_REGION" \
  --query 'services[0].serviceName' \
  --output text > /dev/null 2>&1

if [ $? -ne 0 ]; then
  echo "❌ ECS service '$SERVICE_NAME' not found in cluster '$CLUSTER_NAME'"
  echo "Available services in cluster:"
  aws ecs list-services --cluster "$CLUSTER_NAME" --region "$AWS_REGION" --query 'serviceArns' --output table
  exit 1
fi

echo "✅ ECS service found. Starting force deployment..."

# Force new deployment
echo "🚀 Triggering ECS service force deployment..."
aws ecs update-service \
  --cluster "$CLUSTER_NAME" \
  --service "$SERVICE_NAME" \
  --force-new-deployment \
  --region "$AWS_REGION" \
  --query 'service.{ServiceName:serviceName,TaskDefinition:taskDefinition,DesiredCount:desiredCount,RunningCount:runningCount,PendingCount:pendingCount}' \
  --output table

if [ $? -eq 0 ]; then
  echo "✅ Deployment initiated successfully for ${SERVICE_NAME}"
  echo "📋 Monitor deployment:"
  echo "   aws ecs describe-services --cluster ${CLUSTER_NAME} --services ${SERVICE_NAME} --region ${AWS_REGION}"
else
  echo "❌ ERROR: ECS Force Deployment failed."
  exit 1
fi