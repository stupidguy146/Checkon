import {
  IsBoolean,
  IsDateString,
  IsIn,
  IsInt,
  IsNotEmpty,
  IsNumber,
  IsOptional,
  IsString,
  Max,
  MaxLength,
  Min,
} from 'class-validator';
import { CATEGORIES } from '../../../shared/categories';

export class CreateItemRequest {
  @IsString()
  @IsNotEmpty()
  @MaxLength(160)
  name: string;

  @IsIn(CATEGORIES as unknown as string[])
  category: string;

  @IsOptional() @IsString() @MaxLength(40) size?: string;
  @IsOptional() @IsString() @MaxLength(40) unit?: string;

  @IsInt() @Min(0) @Max(100000) quantity: number;

  @IsNumber({ maxDecimalPlaces: 2 }) @Min(0) price: number;

  @IsOptional() @IsString() @MaxLength(120) store?: string;
  @IsOptional() @IsDateString() purchaseDate?: string;
  @IsOptional() @IsString() @MaxLength(80) buyer?: string;
  @IsOptional() @IsDateString() expiryDate?: string;
  @IsOptional() @IsString() imageBase64?: string;
  @IsOptional() @IsBoolean() notifyRecurring?: boolean;
  @IsOptional() @IsInt() @Min(1) @Max(3650) recurringDays?: number;
}

export class UpdateItemRequest {
  @IsOptional() @IsString() @IsNotEmpty() @MaxLength(160) name?: string;
  @IsOptional() @IsIn(CATEGORIES as unknown as string[]) category?: string;
  @IsOptional() @IsString() @MaxLength(40) size?: string;
  @IsOptional() @IsString() @MaxLength(40) unit?: string;
  @IsOptional() @IsInt() @Min(0) @Max(100000) quantity?: number;
  @IsOptional() @IsNumber({ maxDecimalPlaces: 2 }) @Min(0) price?: number;
  @IsOptional() @IsString() @MaxLength(120) store?: string;
  @IsOptional() @IsDateString() purchaseDate?: string;
  @IsOptional() @IsString() @MaxLength(80) buyer?: string;
  @IsOptional() @IsDateString() expiryDate?: string;
  @IsOptional() @IsString() imageBase64?: string;
  @IsOptional() @IsBoolean() notifyRecurring?: boolean;
  @IsOptional() @IsInt() @Min(1) @Max(3650) recurringDays?: number;
}
