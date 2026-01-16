import { Controller, Get, Param, Query, UseGuards } from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { PricesService } from './prices.service';

@Controller()
@UseGuards(AuthGuard('jwt'))
export class PricesController {
  constructor(private pricesService: PricesService) {}

  @Get('prices/:ticker')
  async getPrice(
    @Param('ticker') ticker: string,
    @Query('type') assetType: string = 'stock',
    @Query('currency') currency: string = 'USD',
  ) {
    return this.pricesService.getPrice(ticker, assetType, currency);
  }

  @Get('search/ticker')
  async searchTickers(@Query('q') query: string) {
    if (!query || query.length < 1) {
      return [];
    }
    return this.pricesService.searchTickers(query);
  }
}
