import { Router } from 'express';
import { DashboardController } from '../controllers/dashboard.controller.js';
import { authMiddleware } from '../middleware/auth.middleware.js';

const router = Router();

router.use(authMiddleware);

router.get('/dashboard', DashboardController.getDashboard);
router.post('/location/update', DashboardController.updateLocation);
router.post('/device/status', DashboardController.updateDeviceStatus);

export default router;
