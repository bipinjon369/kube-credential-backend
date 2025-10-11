# Deployment Guide

## Prerequisites

### Required Software
- AWS CLI configured with appropriate permissions
- Docker installed and running
- Node.js 18+ installed
- Serverless Framework installed: `npm install -g serverless`
- PostgreSQL client installed: `sudo apt-get install postgresql-client` (Ubuntu) or `brew install postgresql` (macOS)

### AWS Credentials Setup

**Option 1: AWS CLI Configuration (Recommended)**
```bash
aws configure
# Enter your AWS Access Key ID, Secret Access Key, Region, and Output format
```

**Option 2: Environment Variables**
```bash
export AWS_ACCESS_KEY_ID=your-access-key
export AWS_SECRET_ACCESS_KEY=your-secret-key
export AWS_DEFAULT_REGION=us-east-1
```

**Option 3: IAM Roles (for EC2 instances)**
- Attach appropriate IAM role to your EC2 instance

### Required AWS Permissions
Your AWS credentials need the following permissions:
- ECR: Full access for container registry
- ECS: Full access for container orchestration
- RDS: Full access for database management
- VPC: Create and manage networking resources
- CloudFormation: Deploy infrastructure stacks
- IAM: Create service roles
- CloudWatch: Create log groups

## Local Development

### Quick Start
```bash
# Start all services with local PostgreSQL
docker-compose up -d
```

### Manual Setup
1. **Install dependencies:**
   ```bash
   npm install
   ```

2. **Start services individually:**
   ```bash
   # Terminal 1 - Issuance Service
   cd services/issuance && npm run dev

   # Terminal 2 - Verification Service
   cd services/verification && npm run dev
   ```

3. **Test endpoints:**
   ```bash
   # Local development (direct service access)
   curl http://localhost:3001/health
   curl http://localhost:3002/health

   # Issue credential (local)
   curl -X POST http://localhost:3001/issuance/credentials \
     -H "Content-Type: application/json" \
     -d '{"name":"John Doe","email":"john@example.com","credentialType":"Developer Certificate"}'

   # Verify credential (local)
   curl -X POST http://localhost:3002/verification/credentials \
     -H "Content-Type: application/json" \
     -d '{"id":"<credential-id>","name":"John Doe","email":"john@example.com"}'

   # Cloud deployment (via ALB)
   curl -X POST http://<alb-dns-name>/issuance/credentials \
     -H "Content-Type: application/json" \
     -d '{"name":"John Doe","email":"john@example.com","credentialType":"Developer Certificate"}'

   curl -X POST http://<alb-dns-name>/verification/credentials \
     -H "Content-Type: application/json" \
     -d '{"id":"<credential-id>"}'
   ```

## AWS Cloud Deployment

### One-Command Deployment
```bash
# Deploy everything (ECR, RDS, ECS, migrations)
./deploy.sh

# Or with custom parameters
./deploy.sh --stage prod --region us-west-2 --password "MySecurePass123"
```

### Manual Step-by-Step Deployment

1. **Deploy infrastructure (ECR + RDS + ECS):**
   ```bash
   serverless deploy --stage dev --param="db-password=SimplePass123"
   ```

2. **Build and push Docker images:**
   ```bash
   # Issuance Service
   cd services/issuance/scripts
   ./push_image.sh
   
   # Verification Service
   cd ../../verification/scripts
   ./push_image.sh
   cd ../../..
   ```

3. **Run database migrations:**
   ```bash
   ./run-migrations.sh --stage dev --region us-east-1
   ```

4. **Deploy ECS services (if needed):**
   ```bash
   # Issuance Service
   cd services/issuance/scripts
   ./deploy_ecs.sh
   
   # Verification Service
   cd ../../verification/scripts
   ./deploy_ecs.sh
   cd ../../..
   ```

### Individual Service Deployment

To deploy services individually after infrastructure is set up:

#### Issuance Service
```bash
cd services/issuance/scripts

# Build and push image
./push_image.sh

# Deploy to ECS (force new deployment)
./deploy_ecs.sh
```

#### Verification Service
```bash
cd services/verification/scripts

# Build and push image
./push_image.sh

# Deploy to ECS (force new deployment)
./deploy_ecs.sh
```

**Note**: The `push_image.sh` scripts will:
- Automatically detect your AWS Account ID
- Use `us-east-1` as default region (override with `AWS_REGION` env var)
- Copy shared libraries and entities
- Build Docker image and push to ECR

**Note**: The `deploy_ecs.sh` scripts will:
- Check if ECS service exists
- Force a new deployment with latest image
- Show deployment status

## Infrastructure Components

### AWS Resources Created
- **ECR Repositories**: `issuance-service`, `verification-service`
- **RDS PostgreSQL**: `kube-credential-backend-dev-postgres` (db.t3.micro)
- **ECS Cluster**: `kube-credential-backend-cluster`
- **ECS Services**: `kube-credential-backend-issuance`, `kube-credential-backend-verification`
- **Application Load Balancer (ALB)**: Routes traffic to ECS services
- **Target Groups**: Health-checked targets for each ECS service
- **VPC**: Custom VPC (10.0.0.0/16) with public subnets across multiple AZs
- **Security Groups**: Layered security (ALB → ECS → RDS)
- **CloudWatch**: Log groups for each service

### Database Configuration
- **Engine**: PostgreSQL 15
- **Instance**: db.t3.micro (free tier eligible)
- **Username**: `dbadmin`
- **Database**: `kube_credentials`
- **SSL**: Disabled for development (enabled via parameter group)

## Environment Variables

Environment variables are automatically configured in ECS task definitions:

```bash
NODE_ENV=production
PORT=3000
AWS_REGION=us-east-1
DB_NAME=kube_credentials
DB_PORT=5432
RDS_CLUSTER_HOST=<auto-generated-from-rds>
RDS_CLUSTER_USERNAME=dbadmin
RDS_CLUSTER_PASSWORD=<from-deployment-parameter>
```

## Monitoring & Troubleshooting

### Health Checks
```bash
# Check service health via Application Load Balancer
curl http://<alb-dns-name>/issuance/health
curl http://<alb-dns-name>/verification/health

# Get ALB DNS name
aws elbv2 describe-load-balancers \
  --query 'LoadBalancers[?contains(LoadBalancerName, `kube-credential`)].DNSName' \
  --output text
```

### Logs
```bash
# View ECS logs
aws logs tail /ecs/kube-credential-backend-issuance --follow
aws logs tail /ecs/kube-credential-backend-verification --follow
```

### Common Issues

#### AWS Credentials Not Found
```bash
# Check AWS credentials
aws sts get-caller-identity

# If not configured, run:
aws configure
```

#### Push Image Script Issues
```bash
# If running from wrong directory, ensure you're in scripts folder:
cd services/issuance/scripts
./push_image.sh

# Or export environment variables manually:
export AWS_REGION=us-east-1
export AWS_ACCOUNT_ID=your-account-id
./push_image.sh
```

#### ECS Service Not Found
```bash
# List available ECS services
aws ecs list-services --cluster kube-credential-backend-cluster

# Check if cluster exists
aws ecs describe-clusters --clusters kube-credential-backend-cluster

# Check target group health
aws elbv2 describe-target-health \
  --target-group-arn $(aws elbv2 describe-target-groups \
    --query 'TargetGroups[?contains(TargetGroupName, `kube-credential`)].TargetGroupArn' \
    --output text | head -1)
```

### Database Connection Test
```bash
# Connect to RDS directly
PGPASSWORD=SimplePass123 psql -h <rds-endpoint> -U dbadmin -d kube_credentials

# Get RDS endpoint
aws rds describe-db-instances \
  --query 'DBInstances[?contains(DBInstanceIdentifier, `kube-credential`)].Endpoint.Address' \
  --output text
```

### ECS Service Status
```bash
# Check service status
aws ecs describe-services \
  --cluster kube-credential-backend-cluster \
  --services kube-credential-backend-issuance kube-credential-backend-verification
```

## Scaling

### Horizontal Scaling
```bash
# Scale issuance service
aws ecs update-service \
  --cluster kube-credential-backend-cluster \
  --service kube-credential-backend-issuance \
  --desired-count 3

# Scale verification service
aws ecs update-service \
  --cluster kube-credential-backend-cluster \
  --service kube-credential-backend-verification \
  --desired-count 2
```

### Vertical Scaling
Update `serverless.yml` CPU/Memory values and redeploy:
```yaml
Cpu: 512      # 0.5 vCPU
Memory: 1024  # 1 GB
```

## Cleanup

```bash
# Remove all AWS resources
serverless remove --stage dev
serverless remove --config serverless-ecr.yml --stage dev

# Remove Docker images locally
docker system prune -a
```

## Load Balancer Configuration

### ALB Setup
- **Type**: Application Load Balancer (Layer 7)
- **Listeners**: HTTP on port 80 (HTTPS on 443 for production)
- **Target Groups**: 
  - Issuance Service: Routes `/issuance/*` paths
  - Verification Service: Routes `/verification/*` paths
- **Health Checks**: `/health` endpoint on each service
- **Auto Scaling**: ECS services scale based on target group health

### Target Group Configuration
```bash
# Check target group health
aws elbv2 describe-target-health \
  --target-group-arn <target-group-arn>

# List target groups
aws elbv2 describe-target-groups \
  --query 'TargetGroups[?contains(TargetGroupName, `kube-credential`)].{Name:TargetGroupName,ARN:TargetGroupArn}'
```

## Production Considerations

- Set `PubliclyAccessible: false` for RDS
- Enable `MultiAZ: true` for RDS
- Set `DeletionProtection: true` for RDS
- Use AWS Secrets Manager for database passwords
- Enable SSL/TLS for database connections
- Configure HTTPS listeners on ALB with SSL certificates
- Set up proper IAM roles with minimal permissions
- Enable AWS CloudTrail for audit logging
- Configure ALB access logs for request tracking
- Set up CloudWatch alarms for target group health