#!/bin/bash

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default values
STAGE="dev"
REGION="us-east-1"
DB_PASSWORD=""

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
    --password)
      DB_PASSWORD="$2"
      shift 2
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

# Generate password if not provided
if [ -z "$DB_PASSWORD" ]; then
  DB_PASSWORD="DbPass$(date +%s | tail -c 6)Abc"
  echo -e "${YELLOW}Generated DB password: $DB_PASSWORD${NC}"
fi

# Note: ECR repositories are now included in main serverless.yml

# Get account ID
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

# Build and push images
echo -e "${GREEN}🐳 Building and pushing Docker images...${NC}"
cd services/issuance/scripts
export AWS_REGION=$REGION
export AWS_ACCOUNT_ID=$ACCOUNT_ID
./push_image.sh
cd ../../verification/scripts
./push_image.sh
cd ../../..

# Deploy main infrastructure with RDS and ECS
echo -e "${GREEN}🏗️ Deploying infrastructure...${NC}"
serverless deploy --stage $STAGE --region $REGION --param="db-password=$DB_PASSWORD"

# Get RDS endpoint
RDS_ENDPOINT=$(aws cloudformation describe-stacks \
  --stack-name kube-credential-backend-$STAGE \
  --query 'Stacks[0].Outputs[?OutputKey==`RDSEndpoint`].OutputValue' \
  --output text \
  --region $REGION)

# Run database migrations
echo -e "${GREEN}🗄️ Running database migrations...${NC}"
./run-migrations.sh --stage $STAGE --region $REGION

echo -e "${GREEN}✅ Deployment completed successfully!${NC}"
echo -e "${YELLOW}📋 Resources created:${NC}"
echo -e "  • ECR Repositories: issuance-service, verification-service"
echo -e "  • RDS Endpoint: $RDS_ENDPOINT"
echo -e "  • ECS Cluster: kube-credential-backend-cluster"
echo -e "  • Database: kube_credentials"
echo -e "  • Username: dbadmin"
echo -e "  • Password: $DB_PASSWORD"