import { Injectable, Logger } from '@nestjs/common';
import { PrismaService } from '../../prisma.service';

@Injectable()
export class SubscriptionsService {
  private readonly logger = new Logger(SubscriptionsService.name);

  constructor(private prisma: PrismaService) {}

  async getSubscription(userId: string) {
    return this.prisma.subscription.findUnique({
      where: { userId },
    });
  }

  async syncSubscription(
    userId: string,
    revenuecatId: string,
    isPremium: boolean,
    expiresAt?: string,
  ) {
    this.logger.log(`Syncing subscription for user ${userId}`);

    // Update or create subscription record
    await this.prisma.subscription.upsert({
      where: { userId },
      update: {
        status: isPremium ? 'active' : 'expired',
        expiresAt: expiresAt ? new Date(expiresAt) : null,
      },
      create: {
        userId,
        revenuecatId,
        status: isPremium ? 'active' : 'free',
        expiresAt: expiresAt ? new Date(expiresAt) : null,
      },
    });

    // Update user subscription status
    await this.prisma.user.update({
      where: { id: userId },
      data: {
        subscriptionStatus: isPremium ? 'premium' : 'free',
      },
    });

    return { success: true };
  }

  async handleRevenueCatEvent(event: any) {
    this.logger.log(`Processing RevenueCat event: ${event.type}`);

    const { app_user_id, type, expiration_at_ms } = event;

    if (!app_user_id) {
      this.logger.warn('No app_user_id in event');
      return { success: false, error: 'No app_user_id' };
    }

    // Find user by RevenueCat ID (which should be our user ID)
    const user = await this.prisma.user.findUnique({
      where: { id: app_user_id },
    });

    if (!user) {
      this.logger.warn(`User not found: ${app_user_id}`);
      return { success: false, error: 'User not found' };
    }

    const expiresAt = expiration_at_ms
      ? new Date(expiration_at_ms)
      : null;

    switch (type) {
      case 'INITIAL_PURCHASE':
      case 'RENEWAL':
      case 'PRODUCT_CHANGE':
        await this.activateSubscription(user.id, app_user_id, expiresAt);
        break;

      case 'CANCELLATION':
      case 'EXPIRATION':
      case 'BILLING_ISSUE':
        await this.deactivateSubscription(user.id);
        break;

      default:
        this.logger.warn(`Unknown event type: ${type}`);
    }

    return { success: true };
  }

  private async activateSubscription(
    userId: string,
    revenuecatId: string,
    expiresAt: Date | null,
  ) {
    await this.prisma.subscription.upsert({
      where: { userId },
      update: {
        status: 'active',
        expiresAt,
        updatedAt: new Date(),
      },
      create: {
        userId,
        revenuecatId,
        status: 'active',
        plan: 'premium',
        expiresAt,
      },
    });

    await this.prisma.user.update({
      where: { id: userId },
      data: { subscriptionStatus: 'premium' },
    });

    this.logger.log(`Subscription activated for user ${userId}`);
  }

  private async deactivateSubscription(userId: string) {
    await this.prisma.subscription.update({
      where: { userId },
      data: {
        status: 'expired',
        updatedAt: new Date(),
      },
    });

    await this.prisma.user.update({
      where: { id: userId },
      data: { subscriptionStatus: 'free' },
    });

    this.logger.log(`Subscription deactivated for user ${userId}`);
  }
}
