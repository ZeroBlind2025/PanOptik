import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma.service';

@Injectable()
export class AuthService {
  constructor(private prisma: PrismaService) {}

  async getMe(userId: string) {
    return this.prisma.user.findUnique({
      where: { id: userId },
      include: {
        subscription: true,
        _count: {
          select: { assets: true, alerts: true },
        },
      },
    });
  }

  async updateFcmToken(userId: string, fcmToken: string) {
    return this.prisma.user.update({
      where: { id: userId },
      data: { fcmToken },
    });
  }
}
