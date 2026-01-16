import {
  IsString,
  IsOptional,
  IsNumber,
  IsEnum,
  Min,
  ValidateIf,
  IsNotEmpty,
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

/**
 * Asset creation rules:
 * - If ticker is provided: quantity is required, manualValue is ignored
 * - If ticker is not provided: manualValue is required, quantity is ignored
 */
export class CreateAssetDto {
  @IsEnum(AssetType)
  type: AssetType;

  @IsString()
  @IsNotEmpty()
  name: string;

  @IsOptional()
  @IsString()
  ticker?: string;

  // Quantity is required when ticker is provided
  @ValidateIf((o) => o.ticker !== undefined && o.ticker !== null && o.ticker !== '')
  @IsNumber()
  @Min(0)
  quantity?: number;

  // ManualValue is required when ticker is NOT provided
  @ValidateIf((o) => !o.ticker)
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
