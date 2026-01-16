import { Controller, Get, Post, Body, UseGuards } from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { SubscriptionsService } from './subscriptions.service';
import { CurrentUser } from '../../common/decorators/current-user.decorator';

@Controller('subscriptions')
@UseGuards(AuthGuard('jwt'))
export class SubscriptionsController {
  constructor(private subscriptionsService: SubscriptionsService) {}

  @Get()
  async getSubscription(@CurrentUser() user: any) {
    return this.subscriptionsService.getSubscription(user.id);
  }

  @Post('sync')
  async syncSubscription(
    @CurrentUser() user: any,
    @Body() body: { revenuecatId: string; isPremium: boolean; expiresAt?: string },
  ) {
    return this.subscriptionsService.syncSubscription(
      user.id,
      body.revenuecatId,
      body.isPremium,
      body.expiresAt,
    );
  }
}
