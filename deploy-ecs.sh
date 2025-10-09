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

echo -e "${GREEN}🏗️ Deploying ECS Infrastructure${NC}"
echo -e "Stage: ${YELLOW}$STAGE${NC}"
echo -e "Region: ${YELLOW}$REGION${NC}"

# Create ECS service-linked role if needed
echo -e "${YELLOW}Creating ECS service-linked role...${NC}"
aws iam create-service-linked-role --aws-service-name ecs.amazonaws.com 2>/dev/null || {
    echo -e "${YELLOW}ECS service-linked role already exists${NC}"
}

# Deploy ECS infrastructure
serverless deploy --config serverless-ecs.yml --stage $STAGE --region $REGION

echo -e "${GREEN}✅ ECS infrastructure deployed successfully!${NC}"
echo -e "${YELLOW}📋 Resources created:${NC}"
echo -e "  • ECS Cluster: kube-credential-ecs-cluster"
echo -e "  • ECS Services: kube-credential-ecs-issuance, kube-credential-ecs-verification"
echo -e "${YELLOW}🔍 Check AWS Console for service status${NC}"