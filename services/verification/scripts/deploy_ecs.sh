#!/bin/bash

set -e

# Load environment variables
if [ -f .env ]; then
    export $(cat .env | grep -v '#' | xargs)
fi

SERVICE_NAME="verification-service"
CLUSTER_NAME="kube-credential-cluster"

echo "Deploying ${SERVICE_NAME} to ECS..."

# Force new deployment
aws ecs update-service \
    --cluster ${CLUSTER_NAME} \
    --service ${SERVICE_NAME} \
    --force-new-deployment \
    --region ${AWS_REGION}

echo "✅ Deployment initiated for ${SERVICE_NAME}"
echo "📋 Monitor deployment:"
echo "   aws ecs describe-services --cluster ${CLUSTER_NAME} --services ${SERVICE_NAME}"