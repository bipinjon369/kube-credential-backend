# Deployment Guide

## Prerequisites

- AWS CLI configured
- Docker installed
- Node.js 18+ installed

## Local Development

1. **Start the database:**
   ```bash
   docker-compose up -d postgres
   ```

2. **Install dependencies:**
   ```bash
   npm install
   cd services/issuance && npm install
   cd ../verification && npm install
   ```

3. **Run services:**
   ```bash
   # Terminal 1 - Issuance Service
   cd services/issuance
   npm run dev

   # Terminal 2 - Verification Service
   cd services/verification
   npm run dev
   ```

4. **Test endpoints:**
   ```bash
   # Health checks
   curl http://localhost:3001/health
   curl http://localhost:3002/health

   # Issue credential
   curl -X POST http://localhost:3001/issuance/credentials \
     -H "Content-Type: application/json" \
     -d '{"name":"John Doe","email":"john@example.com","credentialType":"Developer Certificate"}'

   # Verify credential (use ID from above response)
   curl -X POST http://localhost:3002/verification/credentials \
     -H "Content-Type: application/json" \
     -d '{"id":"<credential-id>","name":"John Doe","email":"john@example.com"}'
   ```

## AWS Deployment

### 1. Setup ECR Repositories

```bash
aws ecr create-repository --repository-name issuance-service --region us-east-1
aws ecr create-repository --repository-name verification-service --region us-east-1
```

### 2. Deploy Services

```bash
# Deploy Issuance Service
cd services/issuance
cp .env.example .env
# Edit .env with your AWS details
./scripts/push_image.sh
./scripts/deploy_ecs.sh

# Deploy Verification Service
cd ../verification
cp .env.example .env
# Edit .env with your AWS details
./scripts/push_image.sh
./scripts/deploy_ecs.sh
```

### 3. Environment Variables

Required environment variables for both services:

```bash
NODE_ENV=production
PORT=3000
LOG_LEVEL=info

# Database
DB_NAME=kube_credentials
DB_PORT=5432
RDS_CLUSTER_HOST=your-rds-endpoint
RDS_CLUSTER_USERNAME=admin
RDS_CLUSTER_PASSWORD=your-password

# AWS
AWS_REGION=us-east-1
AWS_ACCOUNT_ID=123456789012
```

## Monitoring

- **Health Checks**: `/health` endpoint on each service
- **Logs**: CloudWatch logs for each ECS task
- **Metrics**: ECS service metrics in CloudWatch

## Scaling

Services can be scaled independently by updating the ECS service desired count:

```bash
aws ecs update-service \
  --cluster kube-credential-cluster \
  --service issuance-service \
  --desired-count 3
```