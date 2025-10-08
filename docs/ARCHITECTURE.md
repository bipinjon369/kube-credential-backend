# Architecture Overview

## System Design

The Kube Credential Backend consists of two independent microservices:

1. **Issuance Service** - Issues new credentials
2. **Verification Service** - Verifies existing credentials

## Technology Stack

- **Runtime**: Node.js 18 with TypeScript
- **Framework**: Express.js
- **Database**: PostgreSQL with Knex.js
- **Containerization**: Docker
- **Orchestration**: AWS ECS
- **Load Balancing**: Application Load Balancer

## Service Architecture

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

## Key Features

- **Worker ID Tracking**: Each service instance reports its hostname
- **Duplicate Prevention**: Composite unique constraint on credentials
- **Structured Logging**: Winston with request correlation
- **Health Checks**: Built-in health endpoints
- **Error Handling**: Comprehensive error responses
- **Input Validation**: Zod schema validation