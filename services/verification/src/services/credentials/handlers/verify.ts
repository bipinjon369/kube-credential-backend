import { Request, Response } from 'express';
import { z } from 'zod';
import { createDatabaseConnection } from '../../../lib/aws/rds_knex';
import { getWorkerID, createEndpointLogger } from '../../../lib/helper';

const logger = createEndpointLogger('/verification/credentials', 'POST');

const verifyCredentialSchema = z.object({
  id: z.string().uuid('Valid UUID is required'),
  name: z.string().min(1, 'Name is required'),
  email: z.string().email('Valid email is required')
});

export const verifyCredential = async (req: Request, res: Response) => {
  const requestId = req.requestId;
  const workerID = getWorkerID();
  const verifiedAt = new Date();
  
  logger.info('Credential verification started', { requestId, workerID });

  try {
    // Validate input
    const validationResult = verifyCredentialSchema.safeParse(req.body);
    if (!validationResult.success) {
      logger.warn('Validation failed', { requestId, workerID, errors: validationResult.error.errors });
      return res.status(400).json({
        success: false,
        message: 'Validation failed',
        errors: validationResult.error.errors
      });
    }

    const { id, name, email } = validationResult.data;
    const db = createDatabaseConnection();

    // Query credential by ID
    const credential = await db('credentials')
      .where({ id })
      .first();

    if (!credential) {
      logger.info('Credential not found', { requestId, workerID, credentialId: id });
      return res.status(404).json({
        valid: false,
        message: 'Credential not found or invalid',
        verifiedBy: workerID,
        verifiedAt: verifiedAt.toISOString()
      });
    }

    // Optionally verify name/email match
    if (credential.name !== name || credential.email !== email) {
      logger.info('Credential details mismatch', { requestId, workerID, credentialId: id });
      return res.status(404).json({
        valid: false,
        message: 'Credential not found or invalid',
        verifiedBy: workerID,
        verifiedAt: verifiedAt.toISOString()
      });
    }

    logger.info('Credential verified successfully', { requestId, workerID, credentialId: id });

    res.status(200).json({
      valid: true,
      message: 'Credential verified successfully',
      credential: {
        id: credential.id,
        name: credential.name,
        email: credential.email,
        credentialType: credential.credential_type,
        metadata: credential.metadata || {},
        issuedBy: credential.issued_by,
        issuedAt: credential.issued_at
      },
      verifiedBy: workerID,
      verifiedAt: verifiedAt.toISOString()
    });

  } catch (error) {
    logger.error('Error verifying credential', error, { requestId, workerID });
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
};