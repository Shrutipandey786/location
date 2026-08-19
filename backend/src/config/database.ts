import { PrismaClient } from '@prisma/client';

export const prisma = new PrismaClient();

(BigInt.prototype as any).toJSON = function () {
  return Number(this);
};
