import { Router } from 'express';
import { ActivityController } from '../controllers/activity.controller.js';
import { authMiddleware } from '../middleware/auth.middleware.js';

const router = Router();

router.use(authMiddleware);

router.get('/', ActivityController.getActivities);

export default router;
