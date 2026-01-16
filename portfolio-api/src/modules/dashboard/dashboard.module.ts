import { Module } from '@nestjs/common';
import { DashboardController } from './dashboard.controller';
import { DashboardService } from './dashboard.service';
import { PrismaService } from '../../prisma.service';
import { PricesModule } from '../prices/prices.module';

@Module({
  imports: [PricesModule],
  controllers: [DashboardController],
  providers: [DashboardService, PrismaService],
  exports: [DashboardService],
})
export class DashboardModule {}
