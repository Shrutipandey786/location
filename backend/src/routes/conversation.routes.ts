import { Router } from 'express';
import multer from 'multer';
import { ConversationController } from '../controllers/conversation.controller.js';
import { authMiddleware } from '../middleware/auth.middleware.js';

const upload = multer({ storage: multer.memoryStorage() });
const router = Router();

router.use(authMiddleware);

router.get('/', ConversationController.getConversations);
router.get('/search', ConversationController.searchConversations);
router.get('/:peerId', ConversationController.getConversationDetail);
router.post('/:peerId/messages', ConversationController.sendMessage);
router.post('/:peerId/location', ConversationController.sendLocationMessage);
router.post('/:peerId/media', ConversationController.sendMediaMessage);
router.post('/:peerId/voice', upload.single('file'), ConversationController.sendVoiceMessage);
router.put('/:peerId/read', ConversationController.markMessagesAsRead);
router.delete('/:peerId/messages/:messageId', ConversationController.deleteMessage);
router.delete('/messages/:messageId', ConversationController.deleteMessage);
router.delete('/:peerId/messages', ConversationController.clearConversationMessages);
router.delete('/:peerId', ConversationController.clearConversationMessages);

export default router;
