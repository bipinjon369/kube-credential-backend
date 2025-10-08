import { Router } from 'express';
import { verifyCredential } from '../services/credentials/handlers/verify';

const router = Router();

router.post('/credentials', verifyCredential);

export default router;