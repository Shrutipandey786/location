import { Request, Response } from 'express';
import { ConversationService } from '../services/conversation.service.js';

export class ConversationController {
  public static async getConversations(req: Request, res: Response): Promise<void> {
    try {
      const response = await ConversationService.getConversations(req.user!);
      res.status(200).json(response);
    } catch (error: any) {
      res.status(500).json({ error: 'Internal Server Error', message: error.message });
    }
  }

  public static async searchConversations(req: Request, res: Response): Promise<void> {
    try {
      const query = req.query.query as string | undefined;
      const response = await ConversationService.searchConversations(req.user!, query);
      res.status(200).json(response);
    } catch (error: any) {
      res.status(500).json({ error: 'Internal Server Error', message: error.message });
    }
  }

  public static async getConversationDetail(req: Request, res: Response): Promise<void> {
    try {
      const peerId = parseInt(req.params.peerId, 10);
      const response = await ConversationService.getConversationDetail(req.user!, peerId);
      res.status(200).json(response);
    } catch (error: any) {
      res.status(400).json({ error: 'Bad Request', message: error.message });
    }
  }

  public static async sendMessage(req: Request, res: Response): Promise<void> {
    try {
      const peerId = parseInt(req.params.peerId, 10);
      const response = await ConversationService.sendMessage(req.user!, peerId, req.body);
      res.status(200).json(response);
    } catch (error: any) {
      res.status(400).json({ error: 'Bad Request', message: error.message });
    }
  }

  public static async sendLocationMessage(req: Request, res: Response): Promise<void> {
    try {
      const peerId = parseInt(req.params.peerId, 10);
      const response = await ConversationService.sendLocationMessage(req.user!, peerId, req.body);
      res.status(200).json(response);
    } catch (error: any) {
      res.status(400).json({ error: 'Bad Request', message: error.message });
    }
  }

  public static async sendMediaMessage(req: Request, res: Response): Promise<void> {
    try {
      const peerId = parseInt(req.params.peerId, 10);
      const response = await ConversationService.sendMediaMessage(req.user!, peerId, req.body);
      res.status(200).json(response);
    } catch (error: any) {
      res.status(400).json({ error: 'Bad Request', message: error.message });
    }
  }

  public static async sendVoiceMessage(req: Request, res: Response): Promise<void> {
    try {
      const peerId = parseInt(req.params.peerId, 10);
      const file = req.file as Express.Multer.File;
      const pttDurationSeconds = req.body.pttDurationSeconds ? parseInt(req.body.pttDurationSeconds, 10) : 0;
      const latitude = req.body.latitude ? parseFloat(req.body.latitude) : undefined;
      const longitude = req.body.longitude ? parseFloat(req.body.longitude) : undefined;
      const address = req.body.address;

      const response = await ConversationService.sendVoiceMessage(
        req.user!,
        peerId,
        file,
        pttDurationSeconds,
        latitude,
        longitude,
        address
      );
      res.status(200).json(response);
    } catch (error: any) {
      res.status(400).json({ error: 'Bad Request', message: error.message });
    }
  }

  public static async markMessagesAsRead(req: Request, res: Response): Promise<void> {
    try {
      const peerId = parseInt(req.params.peerId, 10);
      await ConversationService.markMessagesAsRead(req.user!, peerId);
      res.status(200).json({ message: 'Messages marked as read' });
    } catch (error: any) {
      res.status(400).json({ error: 'Bad Request', message: error.message });
    }
  }

  public static async deleteMessage(req: Request, res: Response): Promise<void> {
    try {
      const messageId = parseInt(req.params.messageId, 10);
      await ConversationService.deleteMessage(req.user!, messageId);
      res.status(200).json({ message: 'Message deleted successfully' });
    } catch (error: any) {
      res.status(400).json({ error: 'Bad Request', message: error.message });
    }
  }

  public static async clearConversationMessages(req: Request, res: Response): Promise<void> {
    try {
      const peerId = parseInt(req.params.peerId, 10);
      await ConversationService.clearConversationMessages(req.user!, peerId);
      res.status(200).json({ message: 'Conversation cleared successfully' });
    } catch (error: any) {
      res.status(400).json({ error: 'Bad Request', message: error.message });
    }
  }
}
