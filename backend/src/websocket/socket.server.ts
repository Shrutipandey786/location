import { Server as HttpServer } from 'http';
import { Server as SocketIOServer, Socket } from 'socket.io';
import { JwtService } from '../services/jwt.service.js';

class SocketServer {
  private io: SocketIOServer | null = null;
  private userSockets = new Map<string, Set<string>>();

  public init(httpServer: HttpServer): void {
    this.io = new SocketIOServer(httpServer, {
      cors: {
        origin: '*',
        methods: ['GET', 'POST'],
        credentials: true,
      },
    });

    this.io.use((socket: Socket, next) => {
      const token = socket.handshake.auth?.token || socket.handshake.query?.token;
      if (!token) {
        return next();
      }
      const payload = JwtService.verifyToken(token as string);
      if (payload) {
        (socket as any).userId = payload.userId;
      }
      next();
    });

    this.io.on('connection', (socket: Socket) => {
      const userId = (socket as any).userId;
      if (userId) {
        const userIdStr = userId.toString();
        if (!this.userSockets.has(userIdStr)) {
          this.userSockets.set(userIdStr, new Set());
        }
        this.userSockets.get(userIdStr)!.add(socket.id);

        socket.join(`user:${userIdStr}`);
      }

      socket.on('join_conversation', (conversationId: string) => {
        socket.join(`conversation:${conversationId}`);
      });

      socket.on('leave_conversation', (conversationId: string) => {
        socket.leave(`conversation:${conversationId}`);
      });

      socket.on('disconnect', () => {
        if (userId) {
          const userIdStr = userId.toString();
          const userSet = this.userSockets.get(userIdStr);
          if (userSet) {
            userSet.delete(socket.id);
            if (userSet.size === 0) {
              this.userSockets.delete(userIdStr);
            }
          }
        }
      });
    });
  }

  public notifyMessage(messageDto: any, recipientId: bigint | number, senderId: bigint | number): void {
    if (!this.io) return;
    this.io.to(`user:${recipientId.toString()}`).emit('message', messageDto);
    this.io.to(`user:${senderId.toString()}`).emit('message', messageDto);
    this.io.to(`topic/messages/${recipientId.toString()}`).emit('message', messageDto);
    this.io.to(`topic/messages/${senderId.toString()}`).emit('message', messageDto);
  }

  public notifyLocationUpdate(locationDto: any, userId: bigint | number): void {
    if (!this.io) return;
    this.io.emit('location_update', { userId: Number(userId), ...locationDto });
  }
}

export const socketServer = new SocketServer();
