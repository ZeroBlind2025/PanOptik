import { Injectable, Logger } from '@nestjs/common';
import { HttpService } from '@nestjs/axios';
import { ConfigService } from '@nestjs/config';
import { firstValueFrom } from 'rxjs';

export interface CryptoPriceData {
  ticker: string;
  price: number;
  change?: number;
  changePercent?: number;
}

@Injectable()
export class CoinGeckoProvider {
  private readonly logger = new Logger(CoinGeckoProvider.name);
  private readonly apiKey: string;
  private readonly baseUrl: string;

  // Common crypto symbol to CoinGecko ID mapping
  private readonly symbolToId: Record<string, string> = {
    BTC: 'bitcoin',
    ETH: 'ethereum',
    SOL: 'solana',
    XRP: 'ripple',
    ADA: 'cardano',
    DOGE: 'dogecoin',
    DOT: 'polkadot',
    MATIC: 'matic-network',
    LINK: 'chainlink',
    AVAX: 'avalanche-2',
    UNI: 'uniswap',
    ATOM: 'cosmos',
    LTC: 'litecoin',
    BCH: 'bitcoin-cash',
  };

  constructor(
    private httpService: HttpService,
    private configService: ConfigService,
  ) {
    this.apiKey = this.configService.get<string>('pricing.coingecko.apiKey');
    this.baseUrl = this.configService.get<string>('pricing.coingecko.baseUrl');
  }

  async getPrice(symbol: string): Promise<CryptoPriceData | null> {
    try {
      const coinId = this.symbolToId[symbol.toUpperCase()] || symbol.toLowerCase();

      const response = await firstValueFrom(
        this.httpService.get(`${this.baseUrl}/simple/price`, {
          params: {
            ids: coinId,
            vs_currencies: 'usd',
            include_24hr_change: true,
          },
          headers: this.apiKey
            ? { 'x-cg-demo-api-key': this.apiKey }
            : undefined,
        }),
      );

      const data = response.data[coinId];
      if (!data) return null;

      return {
        ticker: symbol.toUpperCase(),
        price: data.usd,
        changePercent: data.usd_24h_change,
        change: data.usd * (data.usd_24h_change / 100),
      };
    } catch (error) {
      this.logger.error(`Failed to fetch crypto price for ${symbol}`, error.message);
      return null;
    }
  }

  async getBatchPrices(symbols: string[]): Promise<Map<string, CryptoPriceData>> {
    const results = new Map<string, CryptoPriceData>();

    try {
      const coinIds = symbols.map(
        (s) => this.symbolToId[s.toUpperCase()] || s.toLowerCase(),
      );

      const response = await firstValueFrom(
        this.httpService.get(`${this.baseUrl}/simple/price`, {
          params: {
            ids: coinIds.join(','),
            vs_currencies: 'usd',
            include_24hr_change: true,
          },
          headers: this.apiKey
            ? { 'x-cg-demo-api-key': this.apiKey }
            : undefined,
        }),
      );

      for (let i = 0; i < symbols.length; i++) {
        const symbol = symbols[i].toUpperCase();
        const coinId = coinIds[i];
        const data = response.data[coinId];

        if (data) {
          results.set(symbol, {
            ticker: symbol,
            price: data.usd,
            changePercent: data.usd_24h_change,
            change: data.usd * (data.usd_24h_change / 100),
          });
        }
      }
    } catch (error) {
      this.logger.error('Failed to fetch batch crypto prices', error.message);
    }

    return results;
  }
}
