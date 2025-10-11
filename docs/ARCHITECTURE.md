# Architecture Overview

## System Design

The Kube Credential Backend is a microservices-based system deployed on AWS ECS with Application Load Balancer for high availability and scalability.

### Core Services
1. **Issuance Service** - Issues new credentials with duplicate prevention
2. **Verification Service** - Verifies existing credentials with optional cross-validation

## Technology Stack

- **Runtime**: Node.js 18 with TypeScript
- **Framework**: Express.js
- **Database**: AWS RDS PostgreSQL with Knex.js
- **Containerization**: Docker with multi-stage builds
- **Orchestration**: AWS ECS Fargate
- **Load Balancing**: Application Load Balancer (ALB)
- **Service Discovery**: ECS Service Connect
- **Logging**: CloudWatch Logs
- **Container Registry**: Amazon ECR

## AWS Infrastructure Architecture

```
                    ┌─────────────────────┐
                    │   Internet Gateway  │
                    └──────────┬──────────┘
                               │
                    ┌─────────────────────┐
                    │ Application Load    │
                    │ Balancer (ALB)      │
                    └──────────┬──────────┘
                               │
              ┌────────────────┼────────────────┐
              │                │                │
    ┌─────────▼─────────┐    ┌─▼───────────────┐
    │   Target Group    │    │   Target Group  │
    │   (Issuance)      │    │ (Verification)  │
    └─────────┬─────────┘    └─┬───────────────┘
              │                │
    ┌─────────▼─────────┐    ┌─▼───────────────┐
    │ ECS Service       │    │ ECS Service     │
    │ (Issuance)        │    │ (Verification)  │
    │ ┌───────────────┐ │    │ ┌─────────────┐ │
    │ │ Fargate Task  │ │    │ │ Fargate Task│ │
    │ │ Port: 3000    │ │    │ │ Port: 3000  │ │
    │ └───────────────┘ │    │ └─────────────┘ │
    └─────────┬─────────┘    └─┬───────────────┘
              │                │
              └────────────────┼────────────────┘
                               │
                    ┌─────────────────────┐
                    │   RDS PostgreSQL    │
                    │   (Multi-AZ)        │
                    │   Port: 5432        │
                    └─────────────────────┘
```

## Network Architecture

### VPC Configuration
- **CIDR**: 10.0.0.0/16
- **Public Subnets**: 10.0.1.0/24, 10.0.2.0/24 (Multi-AZ)
- **Internet Gateway**: For ALB public access
- **Security Groups**: Layered security for ALB, ECS, and RDS

### Load Balancer Setup
- **Type**: Application Load Balancer (Layer 7)
- **Listeners**: HTTP/HTTPS on ports 80/443
- **Target Groups**: 
  - Issuance Service: `/issuance/*`
  - Verification Service: `/verification/*`
- **Health Checks**: `/health` endpoint on each service
- **Routing**: Path-based routing to appropriate target groups

### ECS Configuration
- **Launch Type**: Fargate (serverless containers)
- **CPU**: 256 (0.25 vCPU) per task
- **Memory**: 512 MB per task
- **Auto Scaling**: Based on CPU/memory utilization
- **Service Discovery**: ECS Service Connect for inter-service communication

## Data Flow

### Request Flow
1. **Client Request** → ALB (Port 80/443)
2. **ALB** → Routes based on path to appropriate Target Group
3. **Target Group** → Forwards to healthy ECS tasks
4. **ECS Task** → Processes request and queries RDS
5. **Response** → Returns through ALB to client

### Service Communication
- **External**: Through ALB with path-based routing
- **Internal**: Direct ECS task-to-task via Service Connect
- **Database**: All services connect to shared RDS instance

## Security Architecture

### Network Security
- **ALB Security Group**: Allows HTTP/HTTPS from internet
- **ECS Security Group**: Allows traffic from ALB only
- **RDS Security Group**: Allows PostgreSQL from ECS only

### Application Security
- **Input Validation**: Zod schema validation
- **Request Correlation**: UUID-based request tracking
- **Error Handling**: Sanitized error responses
- **Health Checks**: Authenticated health endpoints

## Scalability & Reliability

### High Availability
- **Multi-AZ Deployment**: Services across multiple availability zones
- **Auto Scaling**: ECS services scale based on demand
- **Load Distribution**: ALB distributes traffic across healthy tasks
- **Database**: RDS with automated backups and Multi-AZ option

### Monitoring & Observability
- **CloudWatch Logs**: Centralized logging for all services
- **CloudWatch Metrics**: ECS, ALB, and RDS metrics
- **Health Checks**: ALB monitors service health
- **Request Tracing**: Correlation IDs for request tracking

## Key Features

- **Microservices Architecture**: Independent, scalable services
- **Worker ID Tracking**: Each task reports its unique identifier
- **Duplicate Prevention**: Database-level unique constraints
- **Structured Logging**: Winston with request correlation
- **Health Monitoring**: Built-in health endpoints with ALB integration
- **Error Handling**: Comprehensive error responses with proper HTTP codes
- **Input Validation**: Zod schema validation with detailed error messages
- **Graceful Degradation**: Services continue operating if dependencies are unavailable