import {
  Controller,
  Get,
  Post,
  Patch,
  Delete,
  Body,
  Param,
  UseGuards,
} from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { AlertsService } from './alerts.service';
import { CreateAlertDto } from './dto/create-alert.dto';
import { UpdateAlertDto } from './dto/update-alert.dto';
import { CurrentUser } from '../../common/decorators/current-user.decorator';

@Controller('alerts')
@UseGuards(AuthGuard('jwt'))
export class AlertsController {
  constructor(private alertsService: AlertsService) {}

  @Get()
  async findAll(@CurrentUser() user: any) {
    return this.alertsService.findAll(user.id);
  }

  @Get(':id')
  async findOne(@CurrentUser() user: any, @Param('id') id: string) {
    return this.alertsService.findOne(user.id, id);
  }

  @Post()
  async create(@CurrentUser() user: any, @Body() dto: CreateAlertDto) {
    return this.alertsService.create(user.id, dto);
  }

  @Patch(':id')
  async update(
    @CurrentUser() user: any,
    @Param('id') id: string,
    @Body() dto: UpdateAlertDto,
  ) {
    return this.alertsService.update(user.id, id, dto);
  }

  @Delete(':id')
  async remove(@CurrentUser() user: any, @Param('id') id: string) {
    return this.alertsService.remove(user.id, id);
  }
}
