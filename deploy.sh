#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default values
STAGE="dev"
REGION="us-east-1"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --stage)
      STAGE="$2"
      shift 2
      ;;
    --region)
      REGION="$2"
      shift 2
      ;;
    -h|--help)
      echo "Usage: $0 [--stage STAGE] [--region REGION]"
      echo "  --stage   Deployment stage (default: dev)"
      echo "  --region  AWS region (default: us-east-1)"
      exit 0
      ;;
    *)
      echo "Unknown option $1"
      exit 1
      ;;
  esac
done

echo -e "${GREEN}🚀 Deploying Kube Credential Backend${NC}"
echo -e "Stage: ${YELLOW}$STAGE${NC}"
echo -e "Region: ${YELLOW}$REGION${NC}"

# Check if serverless is installed
if ! command -v serverless &> /dev/null; then
    echo -e "${RED}❌ Serverless Framework not found. Installing...${NC}"
    npm install -g serverless
fi

# Deploy ECR repositories first
echo -e "${GREEN}📦 Deploying ECR repositories...${NC}"
serverless deploy --config serverless-ecr.yml --stage $STAGE --region $REGION

# Get ECR repository URIs
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ISSUANCE_ECR="${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/issuance-service"
VERIFICATION_ECR="${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/verification-service"

echo -e "${GREEN}🐳 Building and pushing Docker images...${NC}"

# Build and push issuance service
echo -e "${YELLOW}Building issuance service...${NC}"
cd services/issuance
export AWS_REGION=$REGION
export AWS_ACCOUNT_ID=$ACCOUNT_ID
./scripts/push_image.sh
cd ../..

# Build and push verification service
echo -e "${YELLOW}Building verification service...${NC}"
cd services/verification
export AWS_REGION=$REGION
export AWS_ACCOUNT_ID=$ACCOUNT_ID
./scripts/push_image.sh
cd ../..

# Deploy ECS infrastructure
echo -e "${GREEN}🏗️ Deploying ECS infrastructure...${NC}"
serverless deploy --config serverless-ecs.yml --stage $STAGE --region $REGION

echo -e "${GREEN}⏳ Waiting for services to stabilize...${NC}"
sleep 30

# Update ECS services to use new images
echo -e "${GREEN}🔄 Updating ECS services...${NC}"
aws ecs update-service \
  --cluster kube-credential-ecs-cluster \
  --service kube-credential-ecs-issuance \
  --force-new-deployment \
  --region $REGION

aws ecs update-service \
  --cluster kube-credential-ecs-cluster \
  --service kube-credential-ecs-verification \
  --force-new-deployment \
  --region $REGION

echo -e "${GREEN}✅ Deployment completed successfully!${NC}"
echo -e "${YELLOW}📋 Resources created:${NC}"
echo -e "  • ECR Repositories:"
echo -e "    - $ISSUANCE_ECR"
echo -e "    - $VERIFICATION_ECR"
echo -e "  • ECS Cluster: kube-credential-ecs-cluster"
echo -e "  • ECS Services: kube-credential-ecs-issuance, kube-credential-ecs-verification"
echo -e "${YELLOW}🔍 Check AWS Console for service status${NC}"