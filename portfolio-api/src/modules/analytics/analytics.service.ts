import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma.service';
import { PricesService } from '../prices/prices.service';

interface AllocationItem {
  category: string;
  value: number;
  percentage: number;
}

interface RiskFactor {
  factor: string;
  description: string;
  severity: 'low' | 'medium' | 'high';
}

interface RiskAnalysis {
  riskScore: number;
  riskCategory: string;
  riskFactors: RiskFactor[];
  recommendations: string[];
}

interface ExposureData {
  countryExposure: AllocationItem[];
  sectorExposure: AllocationItem[];
}

@Injectable()
export class AnalyticsService {
  constructor(
    private prisma: PrismaService,
    private pricesService: PricesService,
  ) {}

  async getExposure(userId: string): Promise<ExposureData> {
    const assets = await this.getAssetValues(userId);
    const totalValue = assets.reduce((sum, a) => sum + a.currentValue, 0);

    return {
      countryExposure: this.calculateAllocation(assets, 'country', totalValue),
      sectorExposure: this.calculateAllocation(assets, 'sector', totalValue),
    };
  }

  async getRiskAnalysis(userId: string): Promise<RiskAnalysis> {
    const assets = await this.getAssetValues(userId);
    const totalValue = assets.reduce((sum, a) => sum + a.currentValue, 0);

    const riskFactors: RiskFactor[] = [];
    const recommendations: string[] = [];
    let riskScore = 50; // Base score

    // Check concentration risk (>50% in single asset)
    const maxAssetPercentage = Math.max(
      ...assets.map((a) => (a.currentValue / totalValue) * 100),
    );
    if (maxAssetPercentage > 50) {
      riskScore += 20;
      riskFactors.push({
        factor: 'Single Asset Dominance',
        description: `One asset represents ${maxAssetPercentage.toFixed(1)}% of your portfolio`,
        severity: 'high',
      });
      recommendations.push(
        'Consider diversifying to reduce concentration risk',
      );
    } else if (maxAssetPercentage > 30) {
      riskScore += 10;
      riskFactors.push({
        factor: 'Asset Concentration',
        description: `One asset represents ${maxAssetPercentage.toFixed(1)}% of your portfolio`,
        severity: 'medium',
      });
    }

    // Check sector concentration (>40% in one sector)
    const sectorAllocation = this.calculateAllocation(
      assets,
      'sector',
      totalValue,
    );
    const maxSectorPercentage = Math.max(
      ...sectorAllocation.map((s) => s.percentage),
      0,
    );
    if (maxSectorPercentage > 40) {
      riskScore += 15;
      const topSector = sectorAllocation.find(
        (s) => s.percentage === maxSectorPercentage,
      );
      riskFactors.push({
        factor: 'Sector Overexposure',
        description: `${topSector?.category || 'One sector'} represents ${maxSectorPercentage.toFixed(1)}% of your portfolio`,
        severity: 'medium',
      });
      recommendations.push('Consider adding assets from other sectors');
    }

    // Check diversification (fewer than 5 assets)
    if (assets.length < 5) {
      riskScore += 10;
      riskFactors.push({
        factor: 'Low Diversification',
        description: `Portfolio contains only ${assets.length} asset(s)`,
        severity: 'medium',
      });
      recommendations.push(
        'Consider adding more assets to improve diversification',
      );
    }

    // Check cash allocation
    const cashAssets = assets.filter((a) => a.type === 'cash');
    const cashPercentage =
      (cashAssets.reduce((sum, a) => sum + a.currentValue, 0) / totalValue) *
      100;
    if (cashPercentage > 30) {
      riskScore -= 10; // Less risky
      riskFactors.push({
        factor: 'High Cash Allocation',
        description: `${cashPercentage.toFixed(1)}% of portfolio is in cash`,
        severity: 'low',
      });
      recommendations.push(
        'Consider investing excess cash for better returns',
      );
    }

    // Check for fixed income
    const hasFixedIncome = assets.some(
      (a) => a.type === 'bond' || a.type === 'fund',
    );
    if (!hasFixedIncome) {
      riskScore += 5;
      riskFactors.push({
        factor: 'No Fixed Income',
        description: 'Portfolio has no bonds or fixed income assets',
        severity: 'low',
      });
      recommendations.push(
        'Consider adding bonds or fixed income for stability',
      );
    }

    // Clamp score to 0-100
    riskScore = Math.min(100, Math.max(0, riskScore));

    // Determine category
    let riskCategory: string;
    if (riskScore < 40) {
      riskCategory = 'Low Risk';
    } else if (riskScore < 70) {
      riskCategory = 'Medium Risk';
    } else {
      riskCategory = 'High Risk';
    }

    return {
      riskScore,
      riskCategory,
      riskFactors,
      recommendations,
    };
  }

  async exportToCsv(userId: string): Promise<string> {
    const assets = await this.getAssetValues(userId);

    // Generate CSV content
    const headers = [
      'Name',
      'Type',
      'Ticker',
      'Quantity',
      'Current Value',
      'Currency',
      'Country',
      'Sector',
    ];
    const rows = assets.map((a) => [
      a.name,
      a.type,
      a.ticker || '',
      a.quantity?.toString() || '',
      a.currentValue.toFixed(2),
      a.currency,
      a.country || '',
      a.sector || '',
    ]);

    const csv = [headers.join(','), ...rows.map((r) => r.join(','))].join('\n');

    // In production, you would upload this to cloud storage and return a signed URL
    // For now, return base64 encoded data
    return `data:text/csv;base64,${Buffer.from(csv).toString('base64')}`;
  }

  private async getAssetValues(userId: string) {
    const assets = await this.prisma.asset.findMany({
      where: { userId },
    });

    return Promise.all(
      assets.map(async (asset) => {
        let currentValue = 0;

        if (asset.ticker && asset.quantity) {
          const price = await this.pricesService.getPrice(
            asset.ticker,
            asset.type,
          );
          if (price) {
            currentValue = Number(asset.quantity) * Number(price.price);
          }
        } else if (asset.manualValue) {
          currentValue = Number(asset.manualValue);
        }

        return {
          ...asset,
          quantity: asset.quantity ? Number(asset.quantity) : null,
          currentValue,
        };
      }),
    );
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
