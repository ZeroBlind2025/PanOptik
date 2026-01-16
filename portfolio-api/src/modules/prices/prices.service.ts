import { Injectable, Logger } from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';
import { ConfigService } from '@nestjs/config';
import { PrismaService } from '../../prisma.service';
import { PolygonProvider } from './providers/polygon.provider';
import { CoinGeckoProvider } from './providers/coingecko.provider';
import { MetalsApiProvider } from './providers/metalsapi.provider';
import { Decimal } from '@prisma/client/runtime/library';

@Injectable()
export class PricesService {
  private readonly logger = new Logger(PricesService.name);

  constructor(
    private prisma: PrismaService,
    private configService: ConfigService,
    private polygonProvider: PolygonProvider,
    private coinGeckoProvider: CoinGeckoProvider,
    private metalsApiProvider: MetalsApiProvider,
  ) {}

  async getPrice(ticker: string, assetType: string, currency: string = 'USD') {
    // Check cache first
    const cached = await this.prisma.price.findUnique({
      where: {
        ticker_assetType_currency: { ticker, assetType, currency },
      },
    });

    const ttl = this.getTtl(assetType);
    const isStale = !cached || Date.now() - cached.fetchedAt.getTime() > ttl;

    if (!isStale && cached) {
      return cached;
    }

    // Fetch fresh price
    const freshPrice = await this.fetchPrice(ticker, assetType);
    if (!freshPrice) {
      return cached; // Return stale cache if fetch fails
    }

    // Update cache
    const price = await this.prisma.price.upsert({
      where: {
        ticker_assetType_currency: { ticker, assetType, currency },
      },
      update: {
        price: new Decimal(freshPrice.price),
        change: freshPrice.change ? new Decimal(freshPrice.change) : null,
        changePercent: freshPrice.changePercent
          ? new Decimal(freshPrice.changePercent)
          : null,
        previousClose: freshPrice.previousClose
          ? new Decimal(freshPrice.previousClose)
          : null,
        provider: this.getProvider(assetType),
        fetchedAt: new Date(),
      },
      create: {
        ticker,
        assetType,
        currency,
        price: new Decimal(freshPrice.price),
        change: freshPrice.change ? new Decimal(freshPrice.change) : null,
        changePercent: freshPrice.changePercent
          ? new Decimal(freshPrice.changePercent)
          : null,
        previousClose: freshPrice.previousClose
          ? new Decimal(freshPrice.previousClose)
          : null,
        provider: this.getProvider(assetType),
      },
    });

    return price;
  }

  async searchTickers(query: string) {
    return this.polygonProvider.searchTickers(query);
  }

  private async fetchPrice(ticker: string, assetType: string) {
    switch (assetType) {
      case 'stock':
      case 'etf':
        return this.polygonProvider.getPrice(ticker);
      case 'crypto':
        return this.coinGeckoProvider.getPrice(ticker);
      case 'commodity':
        return this.metalsApiProvider.getPrice(ticker);
      default:
        return null;
    }
  }

  private getTtl(assetType: string): number {
    const ttl = this.configService.get('cache.ttl');
    switch (assetType) {
      case 'stock':
      case 'etf':
        return ttl.stock;
      case 'crypto':
        return ttl.crypto;
      case 'commodity':
        return ttl.commodity;
      default:
        return ttl.stock;
    }
  }

  private getProvider(assetType: string): string {
    switch (assetType) {
      case 'stock':
      case 'etf':
        return 'polygon';
      case 'crypto':
        return 'coingecko';
      case 'commodity':
        return 'metalsapi';
      default:
        return 'unknown';
    }
  }

  // Cron jobs for scheduled price updates
  @Cron(CronExpression.EVERY_5_MINUTES)
  async updateCryptoPrices() {
    this.logger.log('Starting scheduled crypto price update');
    await this.updatePricesByType('crypto');
  }

  @Cron('*/15 * * * *') // Every 15 minutes
  async updateStockPrices() {
    this.logger.log('Starting scheduled stock price update');
    await this.updatePricesByType('stock');
    await this.updatePricesByType('etf');
  }

  @Cron('*/30 * * * *') // Every 30 minutes
  async updateCommodityPrices() {
    this.logger.log('Starting scheduled commodity price update');
    await this.updatePricesByType('commodity');
  }

  private async updatePricesByType(assetType: string) {
    try {
      // Get all unique tickers of this type from user assets
      const assets = await this.prisma.asset.findMany({
        where: {
          ticker: { not: null },
          type: assetType,
        },
        select: { ticker: true },
        distinct: ['ticker'],
      });

      const tickers = assets.map((a) => a.ticker).filter(Boolean) as string[];

      for (const ticker of tickers) {
        try {
          await this.getPrice(ticker, assetType);
        } catch (error) {
          this.logger.error(`Failed to update price for ${ticker}`, error.message);
        }
      }

      this.logger.log(`Updated ${tickers.length} ${assetType} prices`);
    } catch (error) {
      this.logger.error(`Failed to update ${assetType} prices`, error.message);
    }
  }
}
