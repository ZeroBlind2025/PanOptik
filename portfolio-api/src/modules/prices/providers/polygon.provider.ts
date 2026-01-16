import { Injectable, Logger } from '@nestjs/common';
import { HttpService } from '@nestjs/axios';
import { ConfigService } from '@nestjs/config';
import { firstValueFrom } from 'rxjs';

export interface PriceData {
  ticker: string;
  price: number;
  change?: number;
  changePercent?: number;
  previousClose?: number;
}

export interface TickerSearchResult {
  symbol: string;
  name: string;
  type: string;
  exchange?: string;
}

@Injectable()
export class PolygonProvider {
  private readonly logger = new Logger(PolygonProvider.name);
  private readonly apiKey: string;
  private readonly baseUrl: string;

  constructor(
    private httpService: HttpService,
    private configService: ConfigService,
  ) {
    this.apiKey = this.configService.get<string>('pricing.polygon.apiKey');
    this.baseUrl = this.configService.get<string>('pricing.polygon.baseUrl');
  }

  async getPrice(ticker: string): Promise<PriceData | null> {
    try {
      const response = await firstValueFrom(
        this.httpService.get(
          `${this.baseUrl}/v2/aggs/ticker/${ticker}/prev`,
          { params: { apiKey: this.apiKey } },
        ),
      );

      const result = response.data.results?.[0];
      if (!result) return null;

      return {
        ticker,
        price: result.c, // close price
        change: result.c - result.o, // close - open
        changePercent: ((result.c - result.o) / result.o) * 100,
        previousClose: result.o, // open (previous close)
      };
    } catch (error) {
      this.logger.error(`Failed to fetch price for ${ticker}`, error.message);
      return null;
    }
  }

  async searchTickers(query: string): Promise<TickerSearchResult[]> {
    try {
      const response = await firstValueFrom(
        this.httpService.get(`${this.baseUrl}/v3/reference/tickers`, {
          params: {
            search: query,
            active: true,
            limit: 10,
            apiKey: this.apiKey,
          },
        }),
      );

      return (response.data.results || []).map((item: any) => ({
        symbol: item.ticker,
        name: item.name,
        type: item.type,
        exchange: item.primary_exchange,
      }));
    } catch (error) {
      this.logger.error(`Failed to search tickers for ${query}`, error.message);
      return [];
    }
  }
}
