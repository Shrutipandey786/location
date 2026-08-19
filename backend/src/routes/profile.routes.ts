import { Router } from 'express';
import { ProfileController } from '../controllers/profile.controller.js';
import { authMiddleware } from '../middleware/auth.middleware.js';

const router = Router();

router.use(authMiddleware);

router.get('/profile', ProfileController.getProfile);
router.get('/device/telemetry', ProfileController.getDeviceTelemetry);
router.get('/settings', ProfileController.getSettings);
router.put('/settings', ProfileController.updateSettings);

export default router;
