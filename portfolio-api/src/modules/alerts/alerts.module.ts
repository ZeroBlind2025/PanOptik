import { Module } from '@nestjs/common';
import { ScheduleModule } from '@nestjs/schedule';
import { AlertsController } from './alerts.controller';
import { AlertsService } from './alerts.service';
import { AlertProcessorService } from './alert-processor.service';
import { NotificationService } from './notification.service';
import { PrismaService } from '../../prisma.service';
import { PricesModule } from '../prices/prices.module';
import { UsersModule } from '../users/users.module';

@Module({
  imports: [ScheduleModule, PricesModule, UsersModule],
  controllers: [AlertsController],
  providers: [
    AlertsService,
    AlertProcessorService,
    NotificationService,
    PrismaService,
  ],
  exports: [AlertsService],
})
export class AlertsModule {}
