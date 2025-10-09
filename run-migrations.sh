#!/bin/bash

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
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

echo -e "${GREEN}🗄️ Running database migrations${NC}"
echo -e "Stage: ${YELLOW}$STAGE${NC}"
echo -e "Region: ${YELLOW}$REGION${NC}"

# Get RDS endpoint from CloudFormation
echo -e "${YELLOW}Getting RDS endpoint...${NC}"
RDS_ENDPOINT=$(aws cloudformation describe-stacks \
  --stack-name kube-credential-backend-$STAGE \
  --query 'Stacks[0].Outputs[?OutputKey==`RDSEndpoint`].OutputValue' \
  --output text \
  --region $REGION)

if [ -z "$RDS_ENDPOINT" ]; then
  echo -e "${RED}❌ Could not get RDS endpoint. Make sure the stack is deployed.${NC}"
  exit 1
fi

echo -e "${GREEN}✅ RDS Endpoint: $RDS_ENDPOINT${NC}"

# Database connection details
DB_NAME="kube_credentials"
DB_USER="dbadmin"
DB_PASSWORD="SimplePass123"  # Use the same password from deployment

echo -e "${YELLOW}Running migrations...${NC}"

# Run init.sql migration
echo -e "${YELLOW}Creating credentials table...${NC}"
PGPASSWORD=$DB_PASSWORD psql \
  -h $RDS_ENDPOINT \
  -U $DB_USER \
  -d $DB_NAME \
  -f infrastructure/database/init.sql

if [ $? -eq 0 ]; then
  echo -e "${GREEN}✅ Database migrations completed successfully!${NC}"
  
  # Verify table creation
  echo -e "${YELLOW}Verifying table creation...${NC}"
  PGPASSWORD=$DB_PASSWORD psql \
    -h $RDS_ENDPOINT \
    -U $DB_USER \
    -d $DB_NAME \
    -c "\dt"
    
  echo -e "${GREEN}✅ Migration verification completed!${NC}"
else
  echo -e "${RED}❌ Migration failed!${NC}"
  exit 1
fi