import {
  IsString,
  IsOptional,
  IsBoolean,
  IsEnum,
  IsDateString,
} from 'class-validator';

export enum AlertType {
  PRICE_ABOVE = 'price_above',
  PRICE_BELOW = 'price_below',
  DATE_REMINDER = 'date_reminder',
  RECURRING_REMINDER = 'recurring_reminder',
}

export class CreateAlertDto {
  @IsEnum(AlertType)
  type: AlertType;

  @IsString()
  message: string;

  @IsOptional()
  @IsString()
  assetId?: string;

  @IsOptional()
  @IsString()
  triggerValue?: string;

  @IsOptional()
  @IsDateString()
  nextFire?: string;

  @IsOptional()
  @IsBoolean()
  recurring?: boolean;

  @IsOptional()
  @IsString()
  rrule?: string;
}
