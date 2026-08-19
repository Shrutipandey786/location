import bcrypt from 'bcryptjs';
import crypto from 'crypto';
import { prisma } from '../config/database.js';
import { jwtConfig } from '../config/jwt.js';

export class AuthService {
  public static async register(data: { name: string; email: string; password: string; confirmPassword?: string }) {
    if (data.confirmPassword && data.password !== data.confirmPassword) {
      throw new Error('Password and confirm password do not match');
    }

    const normalizedEmail = data.email.trim().toLowerCase();

    const existingUser = await prisma.user.findUnique({
      where: { email: normalizedEmail },
    });

    if (existingUser) {
      throw new Error('An account with this email already exists');
    }

    const hashedPassword = await bcrypt.hash(data.password, 10);

    const user = await prisma.user.create({
      data: {
        name: data.name.trim(),
        email: normalizedEmail,
        password: hashedPassword,
        role: 'USER',
      },
    });

    return {
      message: 'Account created successfully',
      id: Number(user.id),
      name: user.name,
      email: user.email,
    };
  }

  public static async authenticate(email: string, password: string) {
    const normalizedEmail = email.trim().toLowerCase();

    const user = await prisma.user.findUnique({
      where: { email: normalizedEmail },
    });

    if (!user) {
      throw new Error('Invalid email or password');
    }

    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) {
      throw new Error('Invalid email or password');
    }

    return user;
  }

  public static async createRefreshToken(userId: bigint) {
    await prisma.refreshToken.deleteMany({
      where: { userId },
    });

    const token = crypto.randomUUID();
    const expiryDate = new Date(Date.now() + jwtConfig.refreshTokenExpirationMs);

    return prisma.refreshToken.create({
      data: {
        token,
        userId,
        expiryDate,
      },
    });
  }

  public static async verifyRefreshToken(token: string) {
    const refreshToken = await prisma.refreshToken.findUnique({
      where: { token },
      include: { user: true },
    });

    if (!refreshToken) {
      throw new Error('Refresh token not found. Please sign in again.');
    }

    if (refreshToken.expiryDate < new Date()) {
      await prisma.refreshToken.delete({ where: { id: refreshToken.id } });
      throw new Error('Refresh token was expired. Please make a new signin request.');
    }

    return refreshToken;
  }

  public static async deleteRefreshToken(token?: string, userId?: bigint) {
    if (token) {
      await prisma.refreshToken.deleteMany({ where: { token } });
    } else if (userId) {
      await prisma.refreshToken.deleteMany({ where: { userId } });
    }
  }
}
