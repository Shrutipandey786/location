import { Request, Response } from 'express';
import { ActivityService } from '../services/activity.service.js';

export class ActivityController {
  public static async getActivities(req: Request, res: Response): Promise<void> {
    try {
      const type = req.query.type as string | undefined;
      const response = await ActivityService.getActivities(req.user!, type);
      res.status(200).json(response);
    } catch (error: any) {
      res.status(500).json({ error: 'Internal Server Error', message: error.message });
    }
  }
}
