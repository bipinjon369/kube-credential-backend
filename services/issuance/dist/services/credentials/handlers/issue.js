"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.issueCredential = void 0;
const zod_1 = require("zod");
const rds_knex_1 = require("../../../lib/aws/rds_knex");
const helper_1 = require("../../../lib/helper");
const logger = (0, helper_1.createEndpointLogger)('/issuance/credentials', 'POST');
const issueCredentialSchema = zod_1.z.object({
    name: zod_1.z.string().min(1, 'Name is required'),
    email: zod_1.z.string().email('Valid email is required'),
    credentialType: zod_1.z.string().min(1, 'Credential type is required'),
    metadata: zod_1.z.record(zod_1.z.any()).optional()
});
const issueCredential = async (req, res) => {
    const requestId = req.requestId;
    const workerID = (0, helper_1.getWorkerID)();
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
        const db = (0, rds_knex_1.createDatabaseConnection)();
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
        const credentialId = (0, helper_1.generateUUID)();
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
    }
    catch (error) {
        logger.error('Error issuing credential', error, { requestId, workerID });
        res.status(500).json({
            success: false,
            message: 'Internal server error'
        });
    }
};
exports.issueCredential = issueCredential;
//# sourceMappingURL=issue.js.map