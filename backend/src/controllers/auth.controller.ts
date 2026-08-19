import { Request, Response } from 'express';
import { AuthService } from '../services/auth.service.js';
import { JwtService } from '../services/jwt.service.js';

export class AuthController {
  public static async register(req: Request, res: Response): Promise<void> {
    try {
      const response = await AuthService.register(req.body);
      res.status(201).json(response);
    } catch (error: any) {
      res.status(400).json({ error: 'Bad Request', message: error.message });
    }
  }

  public static async login(req: Request, res: Response): Promise<void> {
    try {
      const user = await AuthService.authenticate(req.body.email, req.body.password);
      const refreshToken = await AuthService.createRefreshToken(user.id);
      const accessToken = JwtService.generateAccessToken(user.id, user.email, user.role);

      JwtService.setAccessTokenCookie(res, accessToken);
      JwtService.setRefreshTokenCookie(res, refreshToken.token);

      res.status(200).json({
        message: 'Login successful',
        userId: Number(user.id),
        name: user.name,
        email: user.email,
        role: user.role,
      });
    } catch (error: any) {
      res.status(401).json({ error: 'Unauthorized', message: error.message });
    }
  }

  public static async refreshToken(req: Request, res: Response): Promise<void> {
    try {
      let token = req.cookies?.refresh_token;

      if (!token) {
        res.status(401).json({ error: 'Unauthorized', message: 'Refresh token is missing. Please sign in again.' });
        return;
      }

      const refreshToken = await AuthService.verifyRefreshToken(token);
      const newRefreshToken = await AuthService.createRefreshToken(refreshToken.user.id);
      const newAccessToken = JwtService.generateAccessToken(refreshToken.user.id, refreshToken.user.email, refreshToken.user.role);

      JwtService.setAccessTokenCookie(res, newAccessToken);
      JwtService.setRefreshTokenCookie(res, newRefreshToken.token);

      res.status(200).json({ message: 'Token refreshed successfully' });
    } catch (error: any) {
      res.status(401).json({ error: 'Unauthorized', message: error.message });
    }
  }

  public static async logout(req: Request, res: Response): Promise<void> {
    try {
      const refreshToken = req.cookies?.refresh_token;
      await AuthService.deleteRefreshToken(refreshToken, req.user?.id);

      JwtService.clearAuthCookies(res);
      res.status(200).json({ message: 'Logged out successfully' });
    } catch (error: any) {
      res.status(500).json({ error: 'Internal Server Error', message: error.message });
    }
  }

  public static async getCurrentUser(req: Request, res: Response): Promise<void> {
    if (!req.user) {
      res.status(401).json({ error: 'Unauthorized' });
      return;
    }

    res.status(200).json({
      userId: Number(req.user.id),
      name: req.user.name,
      email: req.user.email,
      role: req.user.role,
    });
  }
}
