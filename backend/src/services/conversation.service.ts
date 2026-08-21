import { prisma } from '../config/database.js';
import { AuthenticatedUser } from '../middleware/auth.middleware.js';
import { socketServer } from '../websocket/socket.server.js';
import fs from 'fs';
import path from 'path';
import crypto from 'crypto';

export class ConversationService {
  public static async getConversations(currentUser: AuthenticatedUser) {
    const conversations = await prisma.conversation.findMany({
      where: {
        OR: [{ user1Id: currentUser.id }, { user2Id: currentUser.id }],
      },
      include: {
        user1: true,
        user2: true,
      },
      orderBy: { updatedAt: 'desc' },
    });

    const processedUserIds = new Set<string>();
    const results: any[] = [];

    for (const conv of conversations) {
      const peer = conv.user1Id.toString() === currentUser.id.toString() ? conv.user2 : conv.user1;
      if (peer && peer.id.toString() !== currentUser.id.toString()) {
        processedUserIds.add(peer.id.toString());
        results.push(await this.buildSummaryDto(conv, peer, currentUser));
      }
    }

    const allUsers = await prisma.user.findMany();
    for (const peer of allUsers) {
      if (peer.id.toString() !== currentUser.id.toString() && !processedUserIds.has(peer.id.toString())) {
        processedUserIds.add(peer.id.toString());
        results.push(await this.buildUserSummaryDto(peer));
      }
    }

    return results;
  }

  public static async searchConversations(currentUser: AuthenticatedUser, query?: string) {
    if (!query || query.trim().length === 0) {
      return this.getConversations(currentUser);
    }

    const trimmed = query.trim().toLowerCase();

    const allUsers = await prisma.user.findMany();
    const matchingUsers = allUsers.filter((user) => {
      if (user.id.toString() === currentUser.id.toString()) return false;
      const displayName = this.resolveName(user.name, user.email).toLowerCase();
      const rawName = (user.name || '').toLowerCase();
      const email = (user.email || '').toLowerCase();
      return displayName.includes(trimmed) || rawName.includes(trimmed) || email.includes(trimmed);
    });

    const processedUserIds = new Set<string>();
    const results: any[] = [];

    for (const peer of matchingUsers) {
      processedUserIds.add(peer.id.toString());
      const conv = await prisma.conversation.findFirst({
        where: {
          OR: [
            { user1Id: currentUser.id, user2Id: peer.id },
            { user1Id: peer.id, user2Id: currentUser.id },
          ],
        },
        include: { user1: true, user2: true },
      });

      if (conv) {
        results.push(await this.buildSummaryDto(conv, peer, currentUser));
      } else {
        results.push(await this.buildUserSummaryDto(peer));
      }
    }

    const matchingMessages = await prisma.message.findMany({
      where: {
        text: { contains: trimmed, mode: 'insensitive' },
        conversation: {
          OR: [{ user1Id: currentUser.id }, { user2Id: currentUser.id }],
        },
      },
      include: {
        conversation: {
          include: { user1: true, user2: true },
        },
      },
    });

    for (const msg of matchingMessages) {
      const conv = msg.conversation;
      const peer = conv.user1Id.toString() === currentUser.id.toString() ? conv.user2 : conv.user1;
      if (peer && peer.id.toString() !== currentUser.id.toString() && !processedUserIds.has(peer.id.toString())) {
        processedUserIds.add(peer.id.toString());
        results.push(await this.buildSummaryDto(conv, peer, currentUser));
      }
    }

    return results;
  }

  public static async getConversationDetail(currentUser: AuthenticatedUser, peerId: number | bigint) {
    const peerBigId = BigInt(peerId);
    const peer = await prisma.user.findUnique({ where: { id: peerBigId } });

    if (!peer) {
      throw new Error(`Peer user not found with id: ${peerId}`);
    }

    let conversation = await prisma.conversation.findFirst({
      where: {
        OR: [
          { user1Id: currentUser.id, user2Id: peerBigId },
          { user1Id: peerBigId, user2Id: currentUser.id },
        ],
      },
      include: { user1: true, user2: true },
    });

    if (!conversation) {
      conversation = await prisma.conversation.create({
        data: {
          user1Id: currentUser.id,
          user2Id: peerBigId,
        },
        include: { user1: true, user2: true },
      });
    }

    await prisma.message.updateMany({
      where: {
        conversationId: conversation.id,
        recipientId: currentUser.id,
        isRead: false,
      },
      data: { isRead: true },
    });

    const messages = await prisma.message.findMany({
      where: { conversationId: conversation.id },
      include: { sender: true, recipient: true },
      orderBy: { createdAt: 'asc' },
    });

    const messageDtos = messages.map((msg) => this.mapToMessageDto(msg));
    const summaryDto = await this.buildSummaryDto(conversation, peer, currentUser);

    return {
      id: Number(conversation.id),
      conversationSummary: summaryDto,
      messages: messageDtos,
    };
  }

  public static async sendMessage(
    currentUser: AuthenticatedUser,
    peerId: number | bigint,
    request: { text?: string; type?: string; latitude?: number; longitude?: number; address?: string; cameraImageUrl?: string; pttDurationSeconds?: number }
  ) {
    const peerBigId = BigInt(peerId);
    const peer = await prisma.user.findUnique({ where: { id: peerBigId } });

    if (!peer) {
      throw new Error(`Peer user not found with id: ${peerId}`);
    }

    let conversation = await prisma.conversation.findFirst({
      where: {
        OR: [
          { user1Id: currentUser.id, user2Id: peerBigId },
          { user1Id: peerBigId, user2Id: currentUser.id },
        ],
      },
    });

    const now = new Date();
    if (!conversation) {
      conversation = await prisma.conversation.create({
        data: { user1Id: currentUser.id, user2Id: peerBigId },
      });
    } else {
      await prisma.conversation.update({
        where: { id: conversation.id },
        data: { updatedAt: now },
      });
    }

    const message = await prisma.message.create({
      data: {
        conversationId: conversation.id,
        senderId: currentUser.id,
        recipientId: peerBigId,
        text: request.text || '',
        type: request.type || 'TEXT',
        latitude: request.latitude,
        longitude: request.longitude,
        address: request.address,
        cameraImageUrl: request.cameraImageUrl,
        pttDurationSeconds: request.pttDurationSeconds,
        isRead: false,
        createdAt: now,
      },
      include: { sender: true, recipient: true },
    });

    const dto = this.mapToMessageDto(message);
    socketServer.notifyMessage(dto, peerBigId, currentUser.id);
    return dto;
  }

  public static async sendLocationMessage(
    currentUser: AuthenticatedUser,
    peerId: number | bigint,
    request: { latitude: number; longitude: number; address?: string; text?: string }
  ) {
    const peerBigId = BigInt(peerId);
    const peer = await prisma.user.findUnique({ where: { id: peerBigId } });

    if (!peer) {
      throw new Error(`Peer user not found with id: ${peerId}`);
    }

    const now = new Date();
    const address = request.address && request.address.trim().length > 0
      ? request.address
      : `${request.latitude.toFixed(4)}, ${request.longitude.toFixed(4)}`;

    await prisma.location.create({
      data: {
        userId: currentUser.id,
        latitude: request.latitude,
        longitude: request.longitude,
        address,
        updatedAt: now,
      },
    });

    let conversation = await prisma.conversation.findFirst({
      where: {
        OR: [
          { user1Id: currentUser.id, user2Id: peerBigId },
          { user1Id: peerBigId, user2Id: currentUser.id },
        ],
      },
    });

    if (!conversation) {
      conversation = await prisma.conversation.create({
        data: { user1Id: currentUser.id, user2Id: peerBigId },
      });
    } else {
      await prisma.conversation.update({
        where: { id: conversation.id },
        data: { updatedAt: now },
      });
    }

    const text = request.text && request.text.trim().length > 0 ? request.text : 'Shared GPS Location Pin';

    const message = await prisma.message.create({
      data: {
        conversationId: conversation.id,
        senderId: currentUser.id,
        recipientId: peerBigId,
        text,
        type: 'LOCATION',
        latitude: request.latitude,
        longitude: request.longitude,
        address,
        isRead: false,
        createdAt: now,
      },
      include: { sender: true, recipient: true },
    });

    const dto = this.mapToMessageDto(message);
    socketServer.notifyMessage(dto, peerBigId, currentUser.id);
    return dto;
  }

  public static async sendMediaMessage(
    currentUser: AuthenticatedUser,
    peerId: number | bigint,
    request: { cameraImageUrl?: string; type?: string; text?: string; pttDurationSeconds?: number }
  ) {
    const peerBigId = BigInt(peerId);
    const peer = await prisma.user.findUnique({ where: { id: peerBigId } });

    if (!peer) {
      throw new Error(`Peer user not found with id: ${peerId}`);
    }

    const now = new Date();
    let conversation = await prisma.conversation.findFirst({
      where: {
        OR: [
          { user1Id: currentUser.id, user2Id: peerBigId },
          { user1Id: peerBigId, user2Id: currentUser.id },
        ],
      },
    });

    if (!conversation) {
      conversation = await prisma.conversation.create({
        data: { user1Id: currentUser.id, user2Id: peerBigId },
      });
    } else {
      await prisma.conversation.update({
        where: { id: conversation.id },
        data: { updatedAt: now },
      });
    }

    const type = request.type ? request.type.toUpperCase() : 'MEDIA';
    const text = request.text && request.text.trim().length > 0
      ? request.text
      : (type === 'CAMERA' ? 'Live Camera Snapshot' : 'Push-to-Talk Voice Message');

    const message = await prisma.message.create({
      data: {
        conversationId: conversation.id,
        senderId: currentUser.id,
        recipientId: peerBigId,
        text,
        type,
        cameraImageUrl: request.cameraImageUrl,
        pttDurationSeconds: request.pttDurationSeconds,
        isRead: false,
        createdAt: now,
      },
      include: { sender: true, recipient: true },
    });

    const dto = this.mapToMessageDto(message);
    socketServer.notifyMessage(dto, peerBigId, currentUser.id);
    return dto;
  }

  public static async sendVoiceMessage(
    currentUser: AuthenticatedUser,
    peerId: number | bigint,
    file: Express.Multer.File,
    pttDurationSeconds?: number,
    latitude?: number,
    longitude?: number,
    address?: string
  ) {
    const peerBigId = BigInt(peerId);
    const peer = await prisma.user.findUnique({ where: { id: peerBigId } });

    if (!peer) {
      throw new Error(`Peer user not found with id: ${peerId}`);
    }

    if (!file) {
      throw new Error('Voice audio file cannot be empty');
    }

    const uploadDir = path.join(process.cwd(), 'uploads', 'voice');
    if (!fs.existsSync(uploadDir)) {
      fs.mkdirSync(uploadDir, { recursive: true });
    }

    const ext = path.extname(file.originalname) || '.m4a';
    const fileName = `voice_${crypto.randomUUID()}${ext}`;
    const filePath = path.join(uploadDir, fileName);

    fs.writeFileSync(filePath, file.buffer);
    const audioUrl = `/uploads/voice/${fileName}`;

    const now = new Date();
    let conversation = await prisma.conversation.findFirst({
      where: {
        OR: [
          { user1Id: currentUser.id, user2Id: peerBigId },
          { user1Id: peerBigId, user2Id: currentUser.id },
        ],
      },
    });

    if (!conversation) {
      conversation = await prisma.conversation.create({
        data: { user1Id: currentUser.id, user2Id: peerBigId },
      });
    } else {
      await prisma.conversation.update({
        where: { id: conversation.id },
        data: { updatedAt: now },
      });
    }

    const duration = pttDurationSeconds || 0;
    const text = `Voice memo stream (${Math.floor(duration / 60).toString().padStart(2, '0')}:${(duration % 60).toString().padStart(2, '0')}s)`;

    const message = await prisma.message.create({
      data: {
        conversationId: conversation.id,
        senderId: currentUser.id,
        recipientId: peerBigId,
        text,
        type: 'PTT_VOICE',
        latitude,
        longitude,
        address,
        audioUrl,
        pttDurationSeconds: duration,
        isRead: false,
        createdAt: now,
      },
      include: { sender: true, recipient: true },
    });

    const dto = this.mapToMessageDto(message);
    socketServer.notifyMessage(dto, peerBigId, currentUser.id);
    return dto;
  }

  public static async markMessagesAsRead(currentUser: AuthenticatedUser, peerId: number | bigint) {
    const peerBigId = BigInt(peerId);
    const conv = await prisma.conversation.findFirst({
      where: {
        OR: [
          { user1Id: currentUser.id, user2Id: peerBigId },
          { user1Id: peerBigId, user2Id: currentUser.id },
        ],
      },
    });

    if (conv) {
      await prisma.message.updateMany({
        where: {
          conversationId: conv.id,
          recipientId: currentUser.id,
          isRead: false,
        },
        data: { isRead: true },
      });
    }
  }

  public static async deleteMessage(currentUser: AuthenticatedUser, messageId: number | bigint) {
    const msgBigId = BigInt(messageId);
    const message = await prisma.message.findUnique({ where: { id: msgBigId } });

    if (message) {
      if (message.senderId === currentUser.id || message.recipientId === currentUser.id) {
        await prisma.message.delete({ where: { id: msgBigId } });
      }
    }
  }

  public static async clearConversationMessages(currentUser: AuthenticatedUser, peerId: number | bigint) {
    const peerBigId = BigInt(peerId);
    const conv = await prisma.conversation.findFirst({
      where: {
        OR: [
          { user1Id: currentUser.id, user2Id: peerBigId },
          { user1Id: peerBigId, user2Id: currentUser.id },
        ],
      },
    });

    if (conv) {
      await prisma.message.deleteMany({
        where: { conversationId: conv.id },
      });
      await prisma.conversation.delete({
        where: { id: conv.id },
      });
    }
  }

  private static async buildSummaryDto(conversation: any, peer: any, currentUser: AuthenticatedUser) {
    const loc = await prisma.location.findFirst({
      where: { userId: peer.id },
      orderBy: { updatedAt: 'desc' },
    });

    const status = await prisma.deviceStatus.findUnique({
      where: { userId: peer.id },
    });

    const lastMsg = await prisma.message.findFirst({
      where: { conversationId: conversation.id },
      orderBy: { createdAt: 'desc' },
    });

    const unreadCount = await prisma.message.count({
      where: {
        conversationId: conversation.id,
        recipientId: currentUser.id,
        isRead: false,
      },
    });

    const displayName = this.resolveName(peer.name, peer.email);
    const initials = this.getAvatarInitials(displayName);
    const timeToFormat = lastMsg?.createdAt || conversation.updatedAt || new Date();

    return {
      id: Number(conversation.id),
      peerId: Number(peer.id),
      name: displayName,
      email: peer.email || '',
      avatarInitials: initials,
      online: status?.online ?? true,
      statusMessage: status?.statusMessage || 'Active',
      batteryLevel: status?.batteryLevel ?? 100,
      deviceModel: 'Android',
      latitude: loc?.latitude ?? null,
      longitude: loc?.longitude ?? null,
      address: loc?.address ?? null,
      unreadCount,
      lastMessageText: lastMsg?.text || 'No messages yet',
      lastMessageType: lastMsg?.type || 'TEXT',
      updatedAt: timeToFormat.toISOString().slice(0, 19),
    };
  }

  private static async buildUserSummaryDto(peer: any) {
    const loc = await prisma.location.findFirst({
      where: { userId: peer.id },
      orderBy: { updatedAt: 'desc' },
    });

    const status = await prisma.deviceStatus.findUnique({
      where: { userId: peer.id },
    });

    const displayName = this.resolveName(peer.name, peer.email);
    const initials = this.getAvatarInitials(displayName);

    return {
      id: 0,
      peerId: Number(peer.id),
      name: displayName,
      email: peer.email || '',
      avatarInitials: initials,
      online: status?.online ?? true,
      statusMessage: status?.statusMessage || 'Active',
      batteryLevel: status?.batteryLevel ?? 100,
      deviceModel: 'Android',
      latitude: loc?.latitude ?? null,
      longitude: loc?.longitude ?? null,
      address: loc?.address ?? null,
      unreadCount: 0,
      lastMessageText: 'Start conversation',
      lastMessageType: 'TEXT',
      updatedAt: new Date().toISOString().slice(0, 19),
    };
  }

  private static mapToMessageDto(msg: any) {
    const createdAt = msg.createdAt ? new Date(msg.createdAt).toISOString().slice(0, 19) : new Date().toISOString().slice(0, 19);
    return {
      id: Number(msg.id),
      senderId: Number(msg.senderId),
      senderName: this.resolveName(msg.sender?.name, msg.sender?.email),
      recipientId: Number(msg.recipientId),
      text: msg.text || '',
      type: msg.type || 'TEXT',
      latitude: msg.latitude,
      longitude: msg.longitude,
      address: msg.address,
      cameraImageUrl: msg.cameraImageUrl,
      audioUrl: msg.audioUrl,
      pttDurationSeconds: msg.pttDurationSeconds,
      isRead: msg.isRead ?? false,
      createdAt,
    };
  }

  private static resolveName(name?: string, email?: string): string {
    if (name && name.trim().length > 0) {
      return name.trim();
    }
    if (email && email.includes('@')) {
      let username = email.split('@')[0];
      username = username.replace(/\d+/g, '').replace(/[\._]/g, ' ').trim();
      if (username.length > 0) {
        return username.split(' ').map(w => w.length > 0 ? w[0].toUpperCase() + w.slice(1) : '').join(' ');
      }
      return email.split('@')[0];
    }
    if (email && email.trim().length > 0) {
      return email.trim();
    }
    return 'Registered User';
  }

  private static getAvatarInitials(name?: string): string {
    if (!name || name.trim().length === 0) return 'U';
    const parts = name.trim().split(/\s+/);
    if (parts.length === 1) {
      return parts[0].substring(0, Math.min(2, parts[0].length)).toUpperCase();
    }
    return (parts[0].substring(0, 1) + parts[parts.length - 1].substring(0, 1)).toUpperCase();
  }
}

