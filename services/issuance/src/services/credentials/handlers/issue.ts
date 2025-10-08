import { Request, Response } from 'express';
import { z } from 'zod';
import { createDatabaseConnection } from '../../../lib/aws/rds_knex';
import { getWorkerID, generateUUID, createEndpointLogger } from '../../../lib/helper';

const logger = createEndpointLogger('/issuance/credentials', 'POST');

const issueCredentialSchema = z.object({
  name: z.string().min(1, 'Name is required'),
  email: z.string().email('Valid email is required'),
  credentialType: z.string().min(1, 'Credential type is required'),
  metadata: z.record(z.any()).optional()
});

export const issueCredential = async (req: Request, res: Response) => {
  const requestId = req.requestId;
  const workerID = getWorkerID();
  
  logger.info('Credential issuance started', { requestId, workerID });

  try {
    // Validate input
    const validationResult = issueCredentialSchema.safeParse(req.body);
    if (!validationResult.success) {
      logger.warn('Validation failed', { requestId, workerID, errors: validationResult.error.errors });
      return res.status(400).json({
        success: false,
        message: 'Validation failed',
        errors: validationResult.error.errors
      });
    }

    const { name, email, credentialType, metadata } = validationResult.data;
    const db = createDatabaseConnection();

    // Check for duplicate
    const existingCredential = await db('credentials')
      .where({ name, email, credential_type: credentialType })
      .first();

    if (existingCredential) {
      logger.info('Duplicate credential found', { requestId, workerID, existingId: existingCredential.id });
      return res.status(409).json({
        success: false,
        message: 'Credential already issued',
        existingCredential: {
          id: existingCredential.id,
          issuedBy: existingCredential.issued_by,
          issuedAt: existingCredential.issued_at
        }
      });
    }

    // Create new credential
    const credentialId = generateUUID();
    const now = new Date();

    const newCredential = {
      id: credentialId,
      name,
      email,
      credential_type: credentialType,
      metadata: metadata || null,
      issued_by: workerID,
      issued_at: now,
      created_at: now,
      updated_at: now
    };

    await db('credentials').insert(newCredential);

    logger.info('Credential issued successfully', { requestId, workerID, credentialId });

    res.status(201).json({
      success: true,
      message: `credential issued by ${workerID}`,
      credential: {
        id: credentialId,
        name,
        email,
        credentialType,
        metadata: metadata || {},
        issuedBy: workerID,
        issuedAt: now.toISOString()
      }
    });

  } catch (error) {
    logger.error('Error issuing credential', error, { requestId, workerID });
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
};