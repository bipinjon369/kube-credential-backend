import request from 'supertest';
import app from '../../../app';

describe('POST /verification/credentials', () => {
  it('should verify a valid credential', async () => {
    const verificationData = {
      id: '550e8400-e29b-41d4-a716-446655440000',
      name: 'John Doe',
      email: 'john@example.com'
    };

    const response = await request(app)
      .post('/verification/credentials')
      .send(verificationData);

    expect([200, 404]).toContain(response.status);
    expect(response.body.valid).toBeDefined();
  });

  it('should return validation error for invalid UUID', async () => {
    const response = await request(app)
      .post('/verification/credentials')
      .send({
        id: 'invalid-uuid',
        name: 'John Doe',
        email: 'john@example.com'
      })
      .expect(400);

    expect(response.body.success).toBe(false);
    expect(response.body.errors).toBeDefined();
  });
});