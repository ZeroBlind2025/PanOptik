import {
  IsString,
  IsOptional,
  IsBoolean,
  IsEnum,
  IsDateString,
  ValidateIf,
  IsNotEmpty,
  IsNumber,
} from 'class-validator';

/**
 * Alert Types:
 * - price_above: Triggers when asset price goes above threshold (requires assetId, triggerValue)
 * - price_below: Triggers when asset price goes below threshold (requires assetId, triggerValue)
 * - date_reminder: One-time reminder on specific date (requires nextFire)
 * - recurring_reminder: Repeating reminder (requires nextFire and rrule)
 *
 * Triggered Behavior:
 * - One-time alerts (price_above, price_below, date_reminder): enabled=false after firing
 * - Recurring alerts: lastFired is updated, nextFire is recalculated from rrule, enabled stays true
 */
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
  @IsNotEmpty()
  message: string;

  // Required for price alerts
  @ValidateIf((o) => o.type === AlertType.PRICE_ABOVE || o.type === AlertType.PRICE_BELOW)
  @IsString()
  @IsNotEmpty()
  assetId?: string;

  // Required for price alerts - the price threshold as a number
  @ValidateIf((o) => o.type === AlertType.PRICE_ABOVE || o.type === AlertType.PRICE_BELOW)
  @IsNumber()
  triggerValue?: number;

  // Required for date and recurring reminders
  @ValidateIf((o) => o.type === AlertType.DATE_REMINDER || o.type === AlertType.RECURRING_REMINDER)
  @IsDateString()
  @IsNotEmpty()
  nextFire?: string;

  // Required for recurring reminders - iCal RRULE format
  @ValidateIf((o) => o.type === AlertType.RECURRING_REMINDER)
  @IsString()
  @IsNotEmpty()
  rrule?: string;
}
