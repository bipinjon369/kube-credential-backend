import request from 'supertest';
import app from '../../../app';

describe('POST /issuance/credentials', () => {
  it('should issue a new credential', async () => {
    const credentialData = {
      name: 'John Doe',
      email: 'john@example.com',
      credentialType: 'Developer Certificate',
      metadata: {
        organization: 'Tech Corp',
        expiryDate: '2026-12-31'
      }
    };

    const response = await request(app)
      .post('/issuance/credentials')
      .send(credentialData)
      .expect(201);

    expect(response.body.success).toBe(true);
    expect(response.body.credential.name).toBe(credentialData.name);
    expect(response.body.credential.email).toBe(credentialData.email);
    expect(response.body.credential.id).toBeDefined();
  });

  it('should return validation error for invalid input', async () => {
    const response = await request(app)
      .post('/issuance/credentials')
      .send({})
      .expect(400);

    expect(response.body.success).toBe(false);
    expect(response.body.errors).toBeDefined();
  });
});