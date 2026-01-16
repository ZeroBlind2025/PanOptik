import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma.service';

@Injectable()
export class UsersService {
  constructor(private prisma: PrismaService) {}

  async findById(id: string) {
    return this.prisma.user.findUnique({
      where: { id },
      include: { subscription: true },
    });
  }

  async findBySupabaseId(supabaseId: string) {
    return this.prisma.user.findUnique({
      where: { supabaseId },
      include: { subscription: true },
    });
  }

  async isPremium(userId: string): Promise<boolean> {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { subscriptionStatus: true },
    });
    return user?.subscriptionStatus === 'premium';
  }

  async getAssetCount(userId: string): Promise<number> {
    return this.prisma.asset.count({
      where: { userId },
    });
  }

  async canAddAsset(userId: string): Promise<boolean> {
    const isPremium = await this.isPremium(userId);
    if (isPremium) return true;

    const count = await this.getAssetCount(userId);
    return count < 10;
  }

  async updateSubscriptionStatus(userId: string, status: string) {
    return this.prisma.user.update({
      where: { id: userId },
      data: { subscriptionStatus: status },
    });
  }
}
