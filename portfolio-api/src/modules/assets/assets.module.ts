import { Module } from '@nestjs/common';
import { AssetsController } from './assets.controller';
import { AssetsService } from './assets.service';
import { PrismaService } from '../../prisma.service';
import { UsersModule } from '../users/users.module';

@Module({
  imports: [UsersModule],
  controllers: [AssetsController],
  providers: [AssetsService, PrismaService],
  exports: [AssetsService],
})
export class AssetsModule {}
