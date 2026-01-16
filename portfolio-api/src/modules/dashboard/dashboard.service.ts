import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma.service';
import { PricesService } from '../prices/prices.service';
import { Decimal } from '@prisma/client/runtime/library';

interface AllocationItem {
  category: string;
  value: number;
  percentage: number;
}

interface DashboardData {
  totalValue: number;
  dailyChange: number;
  dailyChangePercent: number;
  weeklyChange: number;
  weeklyChangePercent: number;
  allocationByType: AllocationItem[];
  allocationByCountry: AllocationItem[];
  allocationBySector: AllocationItem[];
  lastUpdated: Date;
}

@Injectable()
export class DashboardService {
  constructor(
    private prisma: PrismaService,
    private pricesService: PricesService,
  ) {}

  async getDashboard(userId: string): Promise<DashboardData> {
    const assets = await this.prisma.asset.findMany({
      where: { userId },
    });

    // Calculate values for each asset
    const assetValues = await Promise.all(
      assets.map(async (asset) => {
        let value = 0;
        let dailyChange = 0;
        let dailyChangePercent = 0;

        if (asset.ticker && asset.quantity) {
          const price = await this.pricesService.getPrice(
            asset.ticker,
            asset.type,
          );
          if (price) {
            value = Number(asset.quantity) * Number(price.price);
            dailyChange = price.change ? Number(asset.quantity) * Number(price.change) : 0;
            dailyChangePercent = price.changePercent ? Number(price.changePercent) : 0;
          }
        } else if (asset.manualValue) {
          value = Number(asset.manualValue);
        }

        return {
          ...asset,
          currentValue: value,
          dailyChange,
          dailyChangePercent,
        };
      }),
    );

    const totalValue = assetValues.reduce((sum, a) => sum + a.currentValue, 0);
    const totalDailyChange = assetValues.reduce((sum, a) => sum + a.dailyChange, 0);

    // Calculate allocations
    const allocationByType = this.calculateAllocation(
      assetValues,
      'type',
      totalValue,
    );
    const allocationByCountry = this.calculateAllocation(
      assetValues,
      'country',
      totalValue,
    );
    const allocationBySector = this.calculateAllocation(
      assetValues,
      'sector',
      totalValue,
    );

    return {
      totalValue,
      dailyChange: totalDailyChange,
      dailyChangePercent: totalValue > 0 ? (totalDailyChange / totalValue) * 100 : 0,
      weeklyChange: totalDailyChange * 5, // Simplified estimate
      weeklyChangePercent:
        totalValue > 0 ? ((totalDailyChange * 5) / totalValue) * 100 : 0,
      allocationByType,
      allocationByCountry,
      allocationBySector,
      lastUpdated: new Date(),
    };
  }

  private calculateAllocation(
    assets: Array<{ currentValue: number; [key: string]: any }>,
    field: string,
    totalValue: number,
  ): AllocationItem[] {
    const groups = new Map<string, number>();

    for (const asset of assets) {
      const category = asset[field] || 'Unknown';
      const current = groups.get(category) || 0;
      groups.set(category, current + asset.currentValue);
    }

    return Array.from(groups.entries())
      .map(([category, value]) => ({
        category: this.formatCategory(category),
        value,
        percentage: totalValue > 0 ? (value / totalValue) * 100 : 0,
      }))
      .sort((a, b) => b.value - a.value);
  }

  private formatCategory(category: string): string {
    return category
      .replace(/_/g, ' ')
      .replace(/\b\w/g, (c) => c.toUpperCase());
  }
}
