import {
  Injectable,
  NotFoundException,
  ForbiddenException,
} from '@nestjs/common';
import { PrismaService } from '../../prisma.service';
import { UsersService } from '../users/users.service';
import { CreateAssetDto } from './dto/create-asset.dto';
import { UpdateAssetDto } from './dto/update-asset.dto';
import { Decimal } from '@prisma/client/runtime/library';

@Injectable()
export class AssetsService {
  constructor(
    private prisma: PrismaService,
    private usersService: UsersService,
  ) {}

  async findAll(userId: string) {
    return this.prisma.asset.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
    });
  }

  async findOne(userId: string, id: string) {
    const asset = await this.prisma.asset.findFirst({
      where: { id, userId },
    });

    if (!asset) {
      throw new NotFoundException('Asset not found');
    }

    return asset;
  }

  async create(userId: string, dto: CreateAssetDto) {
    // Check asset limit for free users
    const canAdd = await this.usersService.canAddAsset(userId);
    if (!canAdd) {
      throw new ForbiddenException(
        'Free tier limited to 10 assets. Upgrade to premium for unlimited assets.',
      );
    }

    return this.prisma.asset.create({
      data: {
        userId,
        type: dto.type,
        name: dto.name,
        ticker: dto.ticker,
        quantity: dto.quantity ? new Decimal(dto.quantity) : null,
        manualValue: dto.manualValue ? new Decimal(dto.manualValue) : null,
        costBasis: dto.costBasis ? new Decimal(dto.costBasis) : null,
        currency: dto.currency || 'USD',
        country: dto.country,
        sector: dto.sector,
        riskCategory: dto.riskCategory,
        notes: dto.notes,
      },
    });
  }

  async update(userId: string, id: string, dto: UpdateAssetDto) {
    // Verify ownership
    await this.findOne(userId, id);

    return this.prisma.asset.update({
      where: { id },
      data: {
        ...(dto.name && { name: dto.name }),
        ...(dto.ticker && { ticker: dto.ticker }),
        ...(dto.quantity !== undefined && {
          quantity: dto.quantity ? new Decimal(dto.quantity) : null,
        }),
        ...(dto.manualValue !== undefined && {
          manualValue: dto.manualValue ? new Decimal(dto.manualValue) : null,
        }),
        ...(dto.costBasis !== undefined && {
          costBasis: dto.costBasis ? new Decimal(dto.costBasis) : null,
        }),
        ...(dto.currency && { currency: dto.currency }),
        ...(dto.country !== undefined && { country: dto.country }),
        ...(dto.sector !== undefined && { sector: dto.sector }),
        ...(dto.riskCategory !== undefined && { riskCategory: dto.riskCategory }),
        ...(dto.notes !== undefined && { notes: dto.notes }),
      },
    });
  }

  async remove(userId: string, id: string) {
    // Verify ownership
    await this.findOne(userId, id);

    await this.prisma.asset.delete({
      where: { id },
    });

    return { deleted: true };
  }

  async getTickerAssets(userId: string) {
    return this.prisma.asset.findMany({
      where: {
        userId,
        ticker: { not: null },
      },
      select: {
        id: true,
        ticker: true,
        type: true,
        quantity: true,
      },
    });
  }
}
