import { Controller, Get, UseGuards } from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { DashboardService } from './dashboard.service';
import { CurrentUser } from '../../common/decorators/current-user.decorator';

@Controller('dashboard')
@UseGuards(AuthGuard('jwt'))
export class DashboardController {
  constructor(private dashboardService: DashboardService) {}

  @Get()
  async getDashboard(@CurrentUser() user: any) {
    return this.dashboardService.getDashboard(user.id);
  }
}
