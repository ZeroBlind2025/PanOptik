import {
  Injectable,
  NotFoundException,
  ForbiddenException,
} from '@nestjs/common';
import { PrismaService } from '../../prisma.service';
import { UsersService } from '../users/users.service';
import { CreateAlertDto, AlertType } from './dto/create-alert.dto';
import { UpdateAlertDto } from './dto/update-alert.dto';

@Injectable()
export class AlertsService {
  constructor(
    private prisma: PrismaService,
    private usersService: UsersService,
  ) {}

  async findAll(userId: string) {
    return this.prisma.alert.findMany({
      where: { userId },
      include: {
        asset: {
          select: { id: true, name: true, ticker: true },
        },
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  async findOne(userId: string, id: string) {
    const alert = await this.prisma.alert.findFirst({
      where: { id, userId },
      include: {
        asset: {
          select: { id: true, name: true, ticker: true },
        },
      },
    });

    if (!alert) {
      throw new NotFoundException('Alert not found');
    }

    return alert;
  }

  async create(userId: string, dto: CreateAlertDto) {
    // Check if price alerts are allowed (premium only)
    const isPriceAlert =
      dto.type === AlertType.PRICE_ABOVE || dto.type === AlertType.PRICE_BELOW;

    if (isPriceAlert) {
      const isPremium = await this.usersService.isPremium(userId);
      if (!isPremium) {
        throw new ForbiddenException(
          'Price alerts require a premium subscription',
        );
      }
    }

    return this.prisma.alert.create({
      data: {
        userId,
        type: dto.type,
        message: dto.message,
        assetId: dto.assetId,
        triggerValue: dto.triggerValue,
        nextFire: dto.nextFire ? new Date(dto.nextFire) : null,
        recurring: dto.recurring || false,
        rrule: dto.rrule,
      },
      include: {
        asset: {
          select: { id: true, name: true, ticker: true },
        },
      },
    });
  }

  async update(userId: string, id: string, dto: UpdateAlertDto) {
    // Verify ownership
    await this.findOne(userId, id);

    return this.prisma.alert.update({
      where: { id },
      data: {
        ...(dto.message && { message: dto.message }),
        ...(dto.triggerValue && { triggerValue: dto.triggerValue }),
        ...(dto.nextFire && { nextFire: new Date(dto.nextFire) }),
        ...(dto.recurring !== undefined && { recurring: dto.recurring }),
        ...(dto.rrule !== undefined && { rrule: dto.rrule }),
        ...(dto.enabled !== undefined && { enabled: dto.enabled }),
      },
      include: {
        asset: {
          select: { id: true, name: true, ticker: true },
        },
      },
    });
  }

  async remove(userId: string, id: string) {
    // Verify ownership
    await this.findOne(userId, id);

    await this.prisma.alert.delete({
      where: { id },
    });

    return { deleted: true };
  }

  async getActiveAlerts() {
    return this.prisma.alert.findMany({
      where: { enabled: true },
      include: {
        asset: {
          select: { id: true, name: true, ticker: true, type: true },
        },
        user: {
          select: { id: true, fcmToken: true },
        },
      },
    });
  }

  async markAsFired(id: string, nextFire?: Date) {
    await this.prisma.alert.update({
      where: { id },
      data: {
        lastFired: new Date(),
        nextFire,
        enabled: nextFire ? true : false, // Disable non-recurring alerts after firing
      },
    });
  }
}
