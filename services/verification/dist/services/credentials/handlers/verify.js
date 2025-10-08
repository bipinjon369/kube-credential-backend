"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.verifyCredential = void 0;
const zod_1 = require("zod");
const rds_knex_1 = require("../../../lib/aws/rds_knex");
const helper_1 = require("../../../lib/helper");
const logger = (0, helper_1.createEndpointLogger)('/verification/credentials', 'POST');
const verifyCredentialSchema = zod_1.z.object({
    id: zod_1.z.string().uuid('Valid UUID is required'),
    name: zod_1.z.string().min(1, 'Name is required'),
    email: zod_1.z.string().email('Valid email is required')
});
const verifyCredential = async (req, res) => {
    const requestId = req.requestId;
    const workerID = (0, helper_1.getWorkerID)();
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
        const db = (0, rds_knex_1.createDatabaseConnection)();
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
    }
    catch (error) {
        logger.error('Error verifying credential', error, { requestId, workerID });
        res.status(500).json({
            success: false,
            message: 'Internal server error'
        });
    }
};
exports.verifyCredential = verifyCredential;
//# sourceMappingURL=verify.js.map