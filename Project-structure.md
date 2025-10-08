Comprehensive Prompt for Kube Credential Backend System
Project Overview
Build a microservice-based credential issuance and verification system called "Kube Credential" following a modular monolith pattern similar to the provided Users Service architecture. The system should have two independent Node.js (TypeScript) microservices deployed as separate ECS services.
Architecture Reference
Use the attached Users Service Developer Guide as a reference for:

Project structure and organization
Modular monolith pattern with service domains
Deployment scripts (push_image.sh, deploy_ecs.sh)
Shared library pattern (lib/ and entities/ folders copied during build)
Express app setup with proper middleware
Logging patterns using Winston
Database connection using Knex.js
Environment variable management
Health check endpoints
Local development workflow with SSH tunneling

Core Requirements
Two Separate Microservices

Credential Issuance Service

Base path: /issuance/credentials
Endpoint: POST /issuance/credentials
Issues new credentials and stores them in database
Prevents duplicate credentials (composite unique: name + email + credentialType)
Returns worker ID in format: "credential issued by {workerID}"
Deploy as separate ECS service with 2-3 tasks


Credential Verification Service

Base path: /verification/credentials
Endpoint: POST /verification/credentials
Verifies if a credential exists in the database
Returns original issuance details + current verifier worker ID
Deploy as separate ECS service with 2-3 tasks



Technical Stack

Backend: Node.js with TypeScript
Framework: Express.js
Database: PostgreSQL (RDS free tier - shared between services)
Database Client: Knex.js for query building
Validation: Zod for input validation
Container: Docker (multi-stage builds)
Registry: Amazon ECR (separate repositories for each service)
Deployment: Custom scripts (push_image.sh, deploy_ecs.sh)
Testing: Jest with supertest
Logging: Winston with structured logging

Project Structure
kube-credential-backend/
├── services/
│   ├── issuance/                          # Issuance microservice
│   │   ├── src/
│   │   │   ├── services/
│   │   │   │   └── credentials/           # Credentials business domain
│   │   │   │       ├── handlers/
│   │   │   │       │   ├── issue.ts       # POST /issuance/credentials
│   │   │   │       │   └── index.ts       # Handler exports
│   │   │   │       ├── utils/
│   │   │   │       │   ├── validation.ts  # Zod schemas
│   │   │   │       │   ├── helpers.ts     # Business logic helpers
│   │   │   │       │   └── constants.ts   # Service constants
│   │   │   │       ├── models/
│   │   │   │       │   ├── credential.model.ts
│   │   │   │       │   └── index.ts
│   │   │   │       └── routes.ts          # Express route definitions
│   │   │   │
│   │   │   ├── shared/                    # Shared utilities within service
│   │   │   │   ├── utils/
│   │   │   │   │   ├── logger.ts          # Winston logger setup
│   │   │   │   │   ├── worker-id.ts       # Worker ID extraction (os.hostname())
│   │   │   │   │   └── index.ts
│   │   │   │   └── types/
│   │   │   │       ├── express.types.ts   # Extended Express types
│   │   │   │       └── index.ts
│   │   │   │
│   │   │   ├── lib/                       # Copied from root during build
│   │   │   │   ├── aws/
│   │   │   │   │   └── rds_knex.ts        # Database connection
│   │   │   │   └── helper.ts              # Common utilities
│   │   │   │
│   │   │   ├── routes/
│   │   │   │   ├── index.ts               # Main route aggregator
│   │   │   │   └── health.ts              # Health check endpoints
│   │   │   │
│   │   │   ├── app.ts                     # Express app setup
│   │   │   └── server.ts                  # Server startup
│   │   │
│   │   ├── scripts/
│   │   │   ├── push_image.sh              # Build & push to ECR
│   │   │   └── deploy_ecs.sh              # Force ECS deployment
│   │   │
│   │   ├── Dockerfile                     # Multi-stage Docker build
│   │   ├── .dockerignore
│   │   ├── package.json
│   │   ├── tsconfig.json
│   │   ├── .env.example
│   │   └── README.md                      # Service-specific docs
│   │
│   └── verification/                      # Verification microservice (same structure)
│       ├── src/
│       │   ├── services/credentials/
│       │   │   ├── handlers/
│       │   │   │   ├── verify.ts          # POST /verification/credentials
│       │   │   │   └── index.ts
│       │   │   ├── utils/, models/, routes.ts
│       │   ├── shared/, lib/, routes/, app.ts, server.ts
│       ├── scripts/, Dockerfile, package.json, etc.
│
├── shared/                                # Root-level shared code
│   ├── lib/                               # Shared libraries
│   │   ├── aws/
│   │   │   └── rds_knex.ts                # Database connection setup
│   │   └── helper.ts                      # Common helper functions
│   │
│   └── entities/                          # Database entity definitions
│       └── credential.entity.ts
│
├── infrastructure/                        # Infrastructure setup
│   ├── database/
│   │   ├── migrations/
│   │   │   └── 001_create_credentials_table.sql
│   │   └── init.sql
│   │
│   └── cloudformation/                    # CloudFormation templates (optional)
│       ├── rds.yml, ecr.yml, ecs-cluster.yml, alb.yml, vpc.yml
│
├── docs/
│   ├── ARCHITECTURE.md
│   ├── API.md
│   └── DEPLOYMENT.md
│
├── README.md                              # Main project documentation
└── docker-compose.yml                     # Local development setup
API Specifications
1. Issuance Service
Endpoint: POST /issuance/credentials
Request:
json{
  "name": "John Doe",
  "email": "john@example.com",
  "credentialType": "Developer Certificate",
  "metadata": {
    "organization": "Tech Corp",
    "expiryDate": "2026-12-31"
  }
}
Success Response (201):
json{
  "success": true,
  "message": "credential issued by ip-10-0-1-123.ec2.internal",
  "credential": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "name": "John Doe",
    "email": "john@example.com",
    "credentialType": "Developer Certificate",
    "metadata": { "organization": "Tech Corp", "expiryDate": "2026-12-31" },
    "issuedBy": "ip-10-0-1-123.ec2.internal",
    "issuedAt": "2025-10-07T10:30:00.000Z"
  }
}
Duplicate Response (409):
json{
  "success": false,
  "message": "Credential already issued",
  "existingCredential": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "issuedBy": "ip-10-0-1-124.ec2.internal",
    "issuedAt": "2025-10-07T09:15:00.000Z"
  }
}
Validation Error (400): Standard error format with field-level details
Business Logic:

Check duplicate using composite unique (name + email + credentialType)
Generate UUID v4 for new credentials
Capture worker ID using os.hostname()
Store in PostgreSQL with Knex
Return worker ID in message

2. Verification Service
Endpoint: POST /verification/credentials
Request:
json{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "name": "John Doe",
  "email": "john@example.com"
}
Valid Response (200):
json{
  "valid": true,
  "message": "Credential verified successfully",
  "credential": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "name": "John Doe",
    "email": "john@example.com",
    "credentialType": "Developer Certificate",
    "metadata": { "organization": "Tech Corp", "expiryDate": "2026-12-31" },
    "issuedBy": "ip-10-0-1-123.ec2.internal",
    "issuedAt": "2025-10-07T10:30:00.000Z"
  },
  "verifiedBy": "ip-10-0-1-125.ec2.internal",
  "verifiedAt": "2025-10-07T11:45:00.000Z"
}
Invalid Response (404):
json{
  "valid": false,
  "message": "Credential not found or invalid",
  "verifiedBy": "ip-10-0-1-125.ec2.internal",
  "verifiedAt": "2025-10-07T11:45:00.000Z"
}
Business Logic:

Query by credential ID
Optionally verify name/email match
Return original issuance details
Include current verifier worker ID
Handle non-existent credentials gracefully

Database Schema
sqlCREATE TABLE credentials (
    id UUID PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL,
    credential_type VARCHAR(100) NOT NULL,
    metadata JSONB,
    issued_by VARCHAR(255) NOT NULL,
    issued_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT unique_credential UNIQUE (name, email, credential_type)
);

CREATE INDEX idx_credentials_email ON credentials(email);
CREATE INDEX idx_credentials_type ON credentials(credential_type);
CREATE INDEX idx_credentials_issued_at ON credentials(issued_at);
Implementation Requirements
Code Structure Pattern (Follow Users Service)

Use modular monolith with service domains
Layered architecture: handlers → services → repositories
Shared utilities in shared/ folder
Common code in lib/ (copied during build)
Express app with middleware (helmet, cors, request ID)
Structured logging with Winston (createEndpointLogger pattern)
Health check endpoints at /health
Worker ID extraction using os.hostname()

Validation

Use Zod schemas for all input validation
Validate in handlers before business logic
Return 400 with field-level error details

Error Handling

Comprehensive try-catch in all handlers
Standard error response format
Log all errors with context (requestId, workerID)
Appropriate HTTP status codes

Database Operations

Use Knex.js for query building
Connection pooling configuration
Proper error handling
Transactions for complex operations (if needed)

Docker & Deployment

Multi-stage Dockerfile (build → production)
Alpine Linux base image
Non-root user for security
Health check in Dockerfile
.dockerignore to exclude node_modules, tests

Deployment Scripts (Follow Users Service Pattern)
push_image.sh:

Load AWS credentials from .env
Copy shared folders (lib/, entities/) into src/
Authenticate with ECR
Build Docker image
Tag and push to ECR
Display summary and next steps

deploy_ecs.sh:

Force update ECS service
Use latest image from ECR
Zero-downtime deployment

Local Development

.env.example with all required variables
SSH tunnel script for RDS connection
Build and run locally: npm run build && node dist/server.js
Health check: curl http://localhost:3000/health

Testing

Jest with supertest for integration tests
Unit tests for services and utilities
Minimum 80% code coverage
Mock database for unit tests

Documentation

Comprehensive README.md with:

Architecture overview
Setup instructions
Local development guide
Deployment workflow
API documentation
Testing instructions


Service-specific READMEs in each service folder
Code comments for complex logic
JSDoc for public functions

Key Implementation Details
Worker ID Extraction
typescriptimport os from 'os'

export const getWorkerID = (): string => {
    return process.env.WORKER_ID || os.hostname()
}
Logger Pattern
typescriptconst logger = createEndpointLogger('/issuance/credentials', 'POST')
logger.info('Operation started', { requestId, workerID, body })
logger.error('Error occurred', error, { requestId, workerID })
Request Flow

Middleware adds requestId to req object
Handler validates input with Zod
Business logic in service layer (optional)
Database operations with Knex
Structured logging at each step
Return standardized response

Environment Variables
Both services need:

AWS_REGION, AWS_ACCOUNT_ID
DB_NAME, DB_PORT, RDS_CLUSTER_HOST, RDS_CLUSTER_USERNAME, RDS_CLUSTER_PASSWORD
NODE_ENV, LOG_LEVEL, PORT
WORKER_ID (optional, defaults to hostname)

Success Criteria
✅ Two independent ECS services deployed with 2-3 tasks each
✅ Clean, modular TypeScript code following Users Service pattern
✅ Proper separation of concerns (handlers, models, utils, routes)
✅ Comprehensive error handling with structured logging
✅ Worker ID tracking in all responses
✅ Duplicate credential prevention working
✅ Database persistence with Knex and PostgreSQL
✅ Unit and integration tests (80%+ coverage)
✅ Docker containerization with multi-stage builds
✅ Deployment scripts (push_image.sh, deploy_ecs.sh)
✅ Load balancing demonstrated across multiple tasks
✅ Health check endpoints functional
✅ Clear documentation (README, API docs, deployment guide)
✅ Local development setup with .env and SSH tunnel
Development Notes

Follow the exact folder structure and patterns from Users Service
Use the same logging, error handling, and middleware patterns
Copy the deployment script patterns exactly
Maintain consistency in naming conventions
Use TypeScript strict mode
No any types - proper typing everywhere
Meaningful variable names and comments
RESTful API conventions
Each service is independently deployable

Generate the complete backend implementation following these specifications with production-ready code quality, proper modularization, and best practices matching the Users Service reference architecture.