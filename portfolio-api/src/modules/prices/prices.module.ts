import { Module } from '@nestjs/common';
import { HttpModule } from '@nestjs/axios';
import { ScheduleModule } from '@nestjs/schedule';
import { PricesController } from './prices.controller';
import { PricesService } from './prices.service';
import { PolygonProvider } from './providers/polygon.provider';
import { CoinGeckoProvider } from './providers/coingecko.provider';
import { MetalsApiProvider } from './providers/metalsapi.provider';
import { PrismaService } from '../../prisma.service';

@Module({
  imports: [HttpModule, ScheduleModule],
  controllers: [PricesController],
  providers: [
    PricesService,
    PolygonProvider,
    CoinGeckoProvider,
    MetalsApiProvider,
    PrismaService,
  ],
  exports: [PricesService],
})
export class PricesModule {}
