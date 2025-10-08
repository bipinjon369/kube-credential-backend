# API Documentation

## Issuance Service

### POST /issuance/credentials

Issues a new credential with duplicate prevention.

**Request Body:**
```json
{
  "name": "string (required)",
  "email": "string (required, valid email)",
  "credentialType": "string (required)",
  "metadata": "object (optional)"
}
```

**Responses:**

**201 Created:**
```json
{
  "success": true,
  "message": "credential issued by {workerID}",
  "credential": {
    "id": "uuid",
    "name": "string",
    "email": "string",
    "credentialType": "string",
    "metadata": "object",
    "issuedBy": "string",
    "issuedAt": "ISO date string"
  }
}
```

**409 Conflict (Duplicate):**
```json
{
  "success": false,
  "message": "Credential already issued",
  "existingCredential": {
    "id": "uuid",
    "issuedBy": "string",
    "issuedAt": "ISO date string"
  }
}
```

## Verification Service

### POST /verification/credentials

Verifies an existing credential by ID and details.

**Request Body:**
```json
{
  "id": "string (required, valid UUID)",
  "name": "string (required)",
  "email": "string (required, valid email)"
}
```

**Responses:**

**200 OK (Valid):**
```json
{
  "valid": true,
  "message": "Credential verified successfully",
  "credential": {
    "id": "uuid",
    "name": "string",
    "email": "string",
    "credentialType": "string",
    "metadata": "object",
    "issuedBy": "string",
    "issuedAt": "ISO date string"
  },
  "verifiedBy": "string",
  "verifiedAt": "ISO date string"
}
```

**404 Not Found (Invalid):**
```json
{
  "valid": false,
  "message": "Credential not found or invalid",
  "verifiedBy": "string",
  "verifiedAt": "ISO date string"
}
```

## Common Error Responses

**400 Bad Request:**
```json
{
  "success": false,
  "message": "Validation failed",
  "errors": [
    {
      "code": "string",
      "message": "string",
      "path": ["string"]
    }
  ]
}
```

**500 Internal Server Error:**
```json
{
  "success": false,
  "message": "Internal server error"
}
```