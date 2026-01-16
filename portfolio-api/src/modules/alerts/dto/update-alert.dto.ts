import { PartialType } from '@nestjs/mapped-types';
import { CreateAlertDto } from './create-alert.dto';
import { IsOptional, IsBoolean } from 'class-validator';

export class UpdateAlertDto extends PartialType(CreateAlertDto) {
  @IsOptional()
  @IsBoolean()
  enabled?: boolean;
}
