import { Router } from 'express';
import { issueCredential } from '../services/credentials/handlers/issue';

const router = Router();

router.post('/credentials', issueCredential);

export default router;