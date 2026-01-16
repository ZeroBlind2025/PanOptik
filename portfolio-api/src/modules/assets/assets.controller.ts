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
import { AssetsService } from './assets.service';
import { CreateAssetDto } from './dto/create-asset.dto';
import { UpdateAssetDto } from './dto/update-asset.dto';
import { CurrentUser } from '../../common/decorators/current-user.decorator';

@Controller('assets')
@UseGuards(AuthGuard('jwt'))
export class AssetsController {
  constructor(private assetsService: AssetsService) {}

  @Get()
  async findAll(@CurrentUser() user: any) {
    return this.assetsService.findAll(user.id);
  }

  @Get(':id')
  async findOne(@CurrentUser() user: any, @Param('id') id: string) {
    return this.assetsService.findOne(user.id, id);
  }

  @Post()
  async create(@CurrentUser() user: any, @Body() dto: CreateAssetDto) {
    return this.assetsService.create(user.id, dto);
  }

  @Patch(':id')
  async update(
    @CurrentUser() user: any,
    @Param('id') id: string,
    @Body() dto: UpdateAssetDto,
  ) {
    return this.assetsService.update(user.id, id, dto);
  }

  @Delete(':id')
  async remove(@CurrentUser() user: any, @Param('id') id: string) {
    return this.assetsService.remove(user.id, id);
  }
}
