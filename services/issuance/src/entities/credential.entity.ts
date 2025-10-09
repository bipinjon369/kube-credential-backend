export interface Credential {
  id: string;
  name: string;
  email: string;
  credentialType: string;
  metadata?: Record<string, any>;
  issuedBy: string;
  issuedAt: Date;
  createdAt: Date;
  updatedAt: Date;
}

export interface CreateCredentialRequest {
  name: string;
  email: string;
  credentialType: string;
  metadata?: Record<string, any>;
}

export interface VerifyCredentialRequest {
  id: string;
  name: string;
  email: string;
}