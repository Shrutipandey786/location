import { Request, Response } from 'express';
import { ProfileService } from '../services/profile.service.js';

export class ProfileController {
  public static async getProfile(req: Request, res: Response): Promise<void> {
    try {
      const response = await ProfileService.getProfile(req.user!);
      res.status(200).json(response);
    } catch (error: any) {
      res.status(500).json({ error: 'Internal Server Error', message: error.message });
    }
  }

  public static async getDeviceTelemetry(req: Request, res: Response): Promise<void> {
    try {
      const response = await ProfileService.getDeviceTelemetry(req.user!);
      res.status(200).json(response);
    } catch (error: any) {
      res.status(500).json({ error: 'Internal Server Error', message: error.message });
    }
  }

  public static async getSettings(req: Request, res: Response): Promise<void> {
    try {
      const response = await ProfileService.getUserSettings(req.user!);
      res.status(200).json(response);
    } catch (error: any) {
      res.status(500).json({ error: 'Internal Server Error', message: error.message });
    }
  }

  public static async updateSettings(req: Request, res: Response): Promise<void> {
    try {
      const response = await ProfileService.updateUserSettings(req.user!, req.body);
      res.status(200).json(response);
    } catch (error: any) {
      res.status(500).json({ error: 'Internal Server Error', message: error.message });
    }
  }
}
