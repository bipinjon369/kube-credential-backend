#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}🔧 Setting up AWS prerequisites...${NC}"

# Create ECS service-linked role if it doesn't exist
echo -e "${YELLOW}Creating ECS service-linked role...${NC}"
aws iam create-service-linked-role --aws-service-name ecs.amazonaws.com 2>/dev/null || {
    echo -e "${YELLOW}ECS service-linked role already exists${NC}"
}

echo -e "${GREEN}✅ AWS setup completed!${NC}"
echo -e "${YELLOW}Now you can run: sls deploy --stage dev${NC}"