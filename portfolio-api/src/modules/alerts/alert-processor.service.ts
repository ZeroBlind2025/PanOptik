import { Injectable, Logger } from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';
import { AlertsService } from './alerts.service';
import { NotificationService } from './notification.service';
import { PricesService } from '../prices/prices.service';
import { AlertType } from './dto/create-alert.dto';

@Injectable()
export class AlertProcessorService {
  private readonly logger = new Logger(AlertProcessorService.name);

  constructor(
    private alertsService: AlertsService,
    private notificationService: NotificationService,
    private pricesService: PricesService,
  ) {}

  @Cron(CronExpression.EVERY_5_MINUTES)
  async processAlerts() {
    this.logger.log('Processing alerts...');

    const alerts = await this.alertsService.getActiveAlerts();

    for (const alert of alerts) {
      try {
        const shouldFire = await this.shouldFireAlert(alert);

        if (shouldFire) {
          await this.fireAlert(alert);
        }
      } catch (error) {
        this.logger.error(
          `Error processing alert ${alert.id}`,
          error.message,
        );
      }
    }
  }

  private async shouldFireAlert(alert: any): Promise<boolean> {
    switch (alert.type) {
      case AlertType.PRICE_ABOVE:
      case AlertType.PRICE_BELOW:
        return this.checkPriceAlert(alert);

      case AlertType.DATE_REMINDER:
      case AlertType.RECURRING_REMINDER:
        return this.checkDateAlert(alert);

      default:
        return false;
    }
  }

  private async checkPriceAlert(alert: any): Promise<boolean> {
    if (!alert.asset?.ticker || !alert.triggerValue) {
      return false;
    }

    const price = await this.pricesService.getPrice(
      alert.asset.ticker,
      alert.asset.type,
    );

    if (!price) return false;

    const currentPrice = Number(price.price);
    const triggerPrice = parseFloat(alert.triggerValue);

    if (alert.type === AlertType.PRICE_ABOVE) {
      return currentPrice >= triggerPrice;
    } else {
      return currentPrice <= triggerPrice;
    }
  }

  private checkDateAlert(alert: any): boolean {
    if (!alert.nextFire) return false;

    const now = new Date();
    const fireTime = new Date(alert.nextFire);

    return now >= fireTime;
  }

  private async fireAlert(alert: any) {
    this.logger.log(`Firing alert ${alert.id}: ${alert.message}`);

    // Send push notification
    if (alert.user?.fcmToken) {
      const title = this.getAlertTitle(alert);
      await this.notificationService.sendPushNotification(
        alert.user.fcmToken,
        title,
        alert.message,
        {
          alertId: alert.id,
          type: alert.type,
          assetId: alert.assetId || '',
        },
      );
    }

    // Calculate next fire time for recurring alerts
    let nextFire: Date | undefined;
    if (alert.recurring && alert.rrule) {
      nextFire = this.calculateNextFire(alert.rrule, new Date());
    }

    // Mark as fired
    await this.alertsService.markAsFired(alert.id, nextFire);
  }

  private getAlertTitle(alert: any): string {
    switch (alert.type) {
      case AlertType.PRICE_ABOVE:
        return `${alert.asset?.ticker || 'Asset'} Price Alert`;
      case AlertType.PRICE_BELOW:
        return `${alert.asset?.ticker || 'Asset'} Price Alert`;
      case AlertType.DATE_REMINDER:
        return 'Reminder';
      case AlertType.RECURRING_REMINDER:
        return 'Reminder';
      default:
        return 'Portfolio Alert';
    }
  }

  private calculateNextFire(rrule: string, fromDate: Date): Date {
    const nextFire = new Date(fromDate);

    // Simple RRULE parsing for FREQ
    if (rrule.includes('FREQ=DAILY')) {
      nextFire.setDate(nextFire.getDate() + 1);
    } else if (rrule.includes('FREQ=WEEKLY')) {
      nextFire.setDate(nextFire.getDate() + 7);
    } else if (rrule.includes('FREQ=MONTHLY')) {
      nextFire.setMonth(nextFire.getMonth() + 1);
    }

    return nextFire;
  }
}
