import dotenv from 'dotenv';
dotenv.config();

export const jwtConfig = {
  secret: process.env.JWT_SECRET || '9a4f2c8d7e1b5a3f6c9d8e2b7a4f1c5e3b9a8d7c6f4e2b1a5d8c7e9f3b2a1c4d',
  accessTokenExpiration: parseInt(process.env.ACCESS_TOKEN_EXPIRATION_SECONDS || '900', 10),
  refreshTokenExpirationMs: parseInt(process.env.REFRESH_TOKEN_EXPIRATION_MS || '604800000', 10),
  cookieSecure: process.env.COOKIE_SECURE === 'true',
  cookieSameSite: (process.env.COOKIE_SAME_SITE || 'lax') as 'lax' | 'strict' | 'none',
};
