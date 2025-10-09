#!/bin/bash

set -e

# Colors for output
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
    *)
      echo "Unknown option $1"
      exit 1
      ;;
  esac
done

echo -e "${GREEN}🐳 Deploying ECR Repositories${NC}"
echo -e "Stage: ${YELLOW}$STAGE${NC}"
echo -e "Region: ${YELLOW}$REGION${NC}"

# Deploy ECR repositories
serverless deploy --config serverless-ecr.yml --stage $STAGE --region $REGION

# Get account ID for output
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

echo -e "${GREEN}✅ ECR repositories deployed successfully!${NC}"
echo -e "${YELLOW}📋 ECR Repository URIs:${NC}"
echo -e "  • Issuance: ${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/issuance-service"
echo -e "  • Verification: ${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/verification-service"
echo -e "${YELLOW}🚀 Next steps:${NC}"
echo -e "  1. Build and push Docker images"
echo -e "  2. Run ./deploy-ecs.sh to deploy ECS services"