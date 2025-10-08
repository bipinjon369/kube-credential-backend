# Verification Service

Credential verification microservice for the Kube Credential Backend.

## API Endpoints

### POST /verification/credentials
Verifies an existing credential.

**Request:**
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "name": "John Doe",
  "email": "john@example.com"
}
```

**Valid Response (200):**
```json
{
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
```

## Development

```bash
npm install
npm run dev
```

## Testing

```bash
npm test
```

## Deployment

```bash
./scripts/push_image.sh
./scripts/deploy_ecs.sh
```