import {
  Controller,
  Post,
  Body,
  Headers,
  UnauthorizedException,
  Logger,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as crypto from 'crypto';
import { SubscriptionsService } from '../subscriptions/subscriptions.service';

@Controller('webhooks')
export class WebhooksController {
  private readonly logger = new Logger(WebhooksController.name);

  constructor(
    private configService: ConfigService,
    private subscriptionsService: SubscriptionsService,
  ) {}

  @Post('revenuecat')
  async handleRevenueCatWebhook(
    @Body() body: any,
    @Headers('authorization') authorization: string,
  ) {
    // Verify webhook signature
    const webhookSecret = this.configService.get<string>(
      'revenuecat.webhookSecret',
    );

    if (webhookSecret && authorization !== `Bearer ${webhookSecret}`) {
      this.logger.warn('Invalid RevenueCat webhook authorization');
      throw new UnauthorizedException('Invalid webhook signature');
    }

    this.logger.log(`Received RevenueCat webhook: ${body.event?.type}`);

    try {
      const result = await this.subscriptionsService.handleRevenueCatEvent(
        body.event,
      );
      return result;
    } catch (error) {
      this.logger.error('Error processing RevenueCat webhook', error.message);
      throw error;
    }
  }
}
