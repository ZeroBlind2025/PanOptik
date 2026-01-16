import { Injectable, Logger } from '@nestjs/common';
import { HttpService } from '@nestjs/axios';
import { ConfigService } from '@nestjs/config';
import { firstValueFrom } from 'rxjs';

export interface MetalPriceData {
  ticker: string;
  price: number;
  change?: number;
  changePercent?: number;
}

@Injectable()
export class MetalsApiProvider {
  private readonly logger = new Logger(MetalsApiProvider.name);
  private readonly apiKey: string;
  private readonly baseUrl: string;

  // Metal symbol mapping
  private readonly symbolToMetal: Record<string, string> = {
    XAU: 'XAU', // Gold
    XAG: 'XAG', // Silver
    XPT: 'XPT', // Platinum
    XPD: 'XPD', // Palladium
    GOLD: 'XAU',
    SILVER: 'XAG',
    PLATINUM: 'XPT',
    PALLADIUM: 'XPD',
  };

  constructor(
    private httpService: HttpService,
    private configService: ConfigService,
  ) {
    this.apiKey = this.configService.get<string>('pricing.metalsApi.apiKey');
    this.baseUrl = this.configService.get<string>('pricing.metalsApi.baseUrl');
  }

  async getPrice(symbol: string): Promise<MetalPriceData | null> {
    try {
      const metalSymbol = this.symbolToMetal[symbol.toUpperCase()] || symbol.toUpperCase();

      const response = await firstValueFrom(
        this.httpService.get(`${this.baseUrl}/latest`, {
          params: {
            access_key: this.apiKey,
            base: 'USD',
            symbols: metalSymbol,
          },
        }),
      );

      if (!response.data.success) {
        this.logger.error(`Metals API error: ${response.data.error?.info}`);
        return null;
      }

      // Metals-API returns rates as USD per ounce inverted
      // We need to convert: 1 / rate = price per ounce in USD
      const rate = response.data.rates?.[metalSymbol];
      if (!rate) return null;

      const price = 1 / rate;

      return {
        ticker: symbol.toUpperCase(),
        price,
      };
    } catch (error) {
      this.logger.error(`Failed to fetch metal price for ${symbol}`, error.message);
      return null;
    }
  }
}
