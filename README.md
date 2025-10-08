# Kube Credential Backend

A microservices-based credential management system built with Node.js, TypeScript, and PostgreSQL.

## Overview

The system consists of two independent microservices:
- **Issuance Service**: Issues new credentials with duplicate prevention
- **Verification Service**: Verifies existing credentials

## Quick Start

### Local Development

1. **Clone and setup:**
   ```bash
   git clone <repository>
   cd kube-credential-backend
   npm install
   ```

2. **Start services:**
   ```bash
   docker-compose up
   ```

3. **Test the APIs:**
   ```bash
   # Issue a credential
   curl -X POST http://localhost:3001/issuance/credentials \
     -H "Content-Type: application/json" \
     -d '{"name":"John Doe","email":"john@example.com","credentialType":"Developer Certificate"}'

   # Verify the credential (use ID from response above)
   curl -X POST http://localhost:3002/verification/credentials \
     -H "Content-Type: application/json" \
     -d '{"id":"<credential-id>","name":"John Doe","email":"john@example.com"}'
   ```

## Architecture

```
┌─────────────────┐    ┌─────────────────┐
│  Issuance       │    │  Verification   │
│  Service        │    │  Service        │
│  Port: 3001     │    │  Port: 3002     │
└─────────────────┘    └─────────────────┘
         │                       │
         └───────────┬───────────┘
                     │
         ┌─────────────────┐
         │   PostgreSQL    │
         │   Database      │
         └─────────────────┘
```

## Features

- ✅ **Microservices Architecture**: Independent, scalable services
- ✅ **Worker ID Tracking**: Each instance reports its hostname
- ✅ **Duplicate Prevention**: Composite unique constraints
- ✅ **Input Validation**: Zod schema validation
- ✅ **Structured Logging**: Winston with request correlation
- ✅ **Health Checks**: Built-in monitoring endpoints
- ✅ **Docker Support**: Multi-stage builds with security
- ✅ **AWS Ready**: ECS deployment scripts included
- ✅ **TypeScript**: Full type safety
- ✅ **Testing**: Jest with 80%+ coverage requirement

## Project Structure

```
kube-credential-backend/
├── services/
│   ├── issuance/           # Credential issuance service
│   └── verification/       # Credential verification service
├── shared/                 # Shared libraries and entities
├── infrastructure/         # Database setup and migrations
├── docs/                   # Documentation
└── docker-compose.yml      # Local development setup
```

## API Endpoints

### Issuance Service (Port 3001)
- `POST /issuance/credentials` - Issue new credential
- `GET /health` - Health check

### Verification Service (Port 3002)
- `POST /verification/credentials` - Verify credential
- `GET /health` - Health check

## Development

### Prerequisites
- Node.js 18+
- Docker
- PostgreSQL (or use Docker Compose)

### Setup

```bash
# Install dependencies
npm install

# Start database
docker-compose up -d postgres

# Run services in development mode
cd services/issuance && npm run dev
cd services/verification && npm run dev
```

### Testing

```bash
# Run all tests
npm test

# Run tests for specific service
cd services/issuance && npm test
cd services/verification && npm test
```

## Deployment

### AWS ECS Deployment

1. **Setup ECR repositories:**
   ```bash
   aws ecr create-repository --repository-name issuance-service
   aws ecr create-repository --repository-name verification-service
   ```

2. **Deploy services:**
   ```bash
   # Issuance Service
   cd services/issuance
   ./scripts/push_image.sh
   ./scripts/deploy_ecs.sh

   # Verification Service
   cd services/verification
   ./scripts/push_image.sh
   ./scripts/deploy_ecs.sh
   ```

## Documentation

- [Architecture](docs/ARCHITECTURE.md) - System design and components
- [API Documentation](docs/API.md) - Detailed API specifications
- [Deployment Guide](docs/DEPLOYMENT.md) - Local and AWS deployment

## Technology Stack

- **Runtime**: Node.js 18 with TypeScript
- **Framework**: Express.js
- **Database**: PostgreSQL with Knex.js
- **Validation**: Zod
- **Logging**: Winston
- **Testing**: Jest + Supertest
- **Containerization**: Docker
- **Orchestration**: AWS ECS

## Environment Variables

Both services require:

```bash
NODE_ENV=development
PORT=3000
LOG_LEVEL=info

# Database
DB_NAME=kube_credentials
DB_PORT=5432
RDS_CLUSTER_HOST=localhost
RDS_CLUSTER_USERNAME=admin
RDS_CLUSTER_PASSWORD=password123

# AWS (for production)
AWS_REGION=us-east-1
AWS_ACCOUNT_ID=123456789012
```

## Contributing

1. Follow the existing code patterns
2. Maintain 80%+ test coverage
3. Use TypeScript strict mode
4. Follow the modular architecture
5. Update documentation for changes
