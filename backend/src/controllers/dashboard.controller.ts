import { Request, Response } from 'express';
import { DashboardService } from '../services/dashboard.service.js';

export class DashboardController {
  public static async getDashboard(req: Request, res: Response): Promise<void> {
    try {
      const response = await DashboardService.getDashboard(req.user!);
      res.status(200).json(response);
    } catch (error: any) {
      res.status(500).json({ error: 'Internal Server Error', message: error.message });
    }
  }

  public static async updateLocation(req: Request, res: Response): Promise<void> {
    try {
      const response = await DashboardService.updateLocation(req.user!, req.body);
      res.status(200).json(response);
    } catch (error: any) {
      res.status(400).json({ error: 'Bad Request', message: error.message });
    }
  }

  public static async updateDeviceStatus(req: Request, res: Response): Promise<void> {
    try {
      const response = await DashboardService.updateDeviceStatus(req.user!, req.body);
      res.status(200).json(response);
    } catch (error: any) {
      res.status(400).json({ error: 'Bad Request', message: error.message });
    }
  }
}
