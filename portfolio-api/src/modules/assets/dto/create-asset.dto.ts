import {
  IsString,
  IsOptional,
  IsNumber,
  IsEnum,
  Min,
} from 'class-validator';

export enum AssetType {
  STOCK = 'stock',
  ETF = 'etf',
  CRYPTO = 'crypto',
  FUND = 'fund',
  BOND = 'bond',
  REAL_ESTATE = 'real_estate',
  CASH = 'cash',
  COMMODITY = 'commodity',
}

export class CreateAssetDto {
  @IsEnum(AssetType)
  type: AssetType;

  @IsString()
  name: string;

  @IsOptional()
  @IsString()
  ticker?: string;

  @IsOptional()
  @IsNumber()
  @Min(0)
  quantity?: number;

  @IsOptional()
  @IsNumber()
  @Min(0)
  manualValue?: number;

  @IsOptional()
  @IsNumber()
  @Min(0)
  costBasis?: number;

  @IsOptional()
  @IsString()
  currency?: string = 'USD';

  @IsOptional()
  @IsString()
  country?: string;

  @IsOptional()
  @IsString()
  sector?: string;

  @IsOptional()
  @IsString()
  riskCategory?: string;

  @IsOptional()
  @IsString()
  notes?: string;
}
