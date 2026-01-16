import { Controller, Get, UseGuards } from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { AnalyticsService } from './analytics.service';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { PremiumGuard } from '../../common/guards/premium.guard';

@Controller('analytics')
@UseGuards(AuthGuard('jwt'), PremiumGuard)
export class AnalyticsController {
  constructor(private analyticsService: AnalyticsService) {}

  @Get('exposure')
  async getExposure(@CurrentUser() user: any) {
    return this.analyticsService.getExposure(user.id);
  }

  @Get('risk')
  async getRiskAnalysis(@CurrentUser() user: any) {
    return this.analyticsService.getRiskAnalysis(user.id);
  }
}

@Controller('export')
@UseGuards(AuthGuard('jwt'), PremiumGuard)
export class ExportController {
  constructor(private analyticsService: AnalyticsService) {}

  @Get('csv')
  async exportCsv(@CurrentUser() user: any) {
    const downloadUrl = await this.analyticsService.exportToCsv(user.id);
    return { downloadUrl };
  }
}
