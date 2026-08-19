import jwt from 'jsonwebtoken';
import { Response } from 'express';
import { jwtConfig } from '../config/jwt.js';

export interface JwtPayload {
  userId: number;
  sub: string;
  role: string;
}

export class JwtService {
  public static generateAccessToken(userId: number | bigint, email: string, role: string): string {
    return jwt.sign(
      {
        userId: Number(userId),
        role,
      },
      jwtConfig.secret,
      {
        subject: email,
        expiresIn: jwtConfig.accessTokenExpiration,
      }
    );
  }

  public static verifyToken(token: string): JwtPayload | null {
    try {
      const decoded = jwt.verify(token, jwtConfig.secret) as any;
      return {
        userId: decoded.userId,
        sub: decoded.sub,
        role: decoded.role,
      };
    } catch {
      return null;
    }
  }

  public static setAccessTokenCookie(res: Response, token: string): void {
    res.cookie('access_token', token, {
      httpOnly: true,
      secure: jwtConfig.cookieSecure,
      path: '/',
      maxAge: jwtConfig.accessTokenExpiration * 1000,
      sameSite: jwtConfig.cookieSameSite,
    });
  }

  public static setRefreshTokenCookie(res: Response, token: string): void {
    res.cookie('refresh_token', token, {
      httpOnly: true,
      secure: jwtConfig.cookieSecure,
      path: '/',
      maxAge: jwtConfig.refreshTokenExpirationMs,
      sameSite: jwtConfig.cookieSameSite,
    });
  }

  public static clearAuthCookies(res: Response): void {
    res.cookie('access_token', '', {
      httpOnly: true,
      secure: jwtConfig.cookieSecure,
      path: '/',
      maxAge: 0,
      sameSite: jwtConfig.cookieSameSite,
    });
    res.cookie('refresh_token', '', {
      httpOnly: true,
      secure: jwtConfig.cookieSecure,
      path: '/',
      maxAge: 0,
      sameSite: jwtConfig.cookieSameSite,
    });
  }
}
