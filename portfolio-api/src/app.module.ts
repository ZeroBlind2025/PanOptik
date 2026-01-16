import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { ScheduleModule } from '@nestjs/schedule';
import { HttpModule } from '@nestjs/axios';

import configuration from './config/configuration';
import { PrismaService } from './prisma.service';
import { AuthModule } from './modules/auth/auth.module';
import { UsersModule } from './modules/users/users.module';
import { AssetsModule } from './modules/assets/assets.module';
import { PricesModule } from './modules/prices/prices.module';
import { AlertsModule } from './modules/alerts/alerts.module';
import { DashboardModule } from './modules/dashboard/dashboard.module';
import { AnalyticsModule } from './modules/analytics/analytics.module';
import { SubscriptionsModule } from './modules/subscriptions/subscriptions.module';
import { WebhooksModule } from './modules/webhooks/webhooks.module';
import { HealthModule } from './modules/health/health.module';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      load: [configuration],
    }),
    ScheduleModule.forRoot(),
    HttpModule,
    HealthModule,
    AuthModule,
    UsersModule,
    AssetsModule,
    PricesModule,
    AlertsModule,
    DashboardModule,
    AnalyticsModule,
    SubscriptionsModule,
    WebhooksModule,
  ],
  providers: [PrismaService],
  exports: [PrismaService],
})
export class AppModule {}
