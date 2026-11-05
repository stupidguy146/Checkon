import {
  IsBoolean,
  IsDateString,
  IsIn,
  IsInt,
  IsNotEmpty,
  IsNumber,
  IsObject,
  IsOptional,
  IsString,
  Max,
  MaxLength,
  Min,
  ValidateNested,
} from 'class-validator';
import { Type } from 'class-transformer';
import { CATEGORIES } from '../../../shared/categories';

const STATUSES = ['in_stock', 'low', 'out'] as const;

export class InitialPurchaseRequest {
  @IsInt() @Min(0) @Max(100000) quantity: number;
  @IsNumber({ maxDecimalPlaces: 2 }) @Min(0) price: number;
  @IsOptional() @IsString() @MaxLength(80) buyer?: string;
  @IsOptional() @IsString() @MaxLength(120) store?: string;
  @IsOptional() @IsDateString() purchasedAt?: string;
}

export class CreateProductRequest {
  @IsString() @IsNotEmpty() @MaxLength(160) name: string;
  @IsIn(CATEGORIES as unknown as string[]) category: string;
  @IsOptional() @IsString() @MaxLength(40) size?: string;
  @IsOptional() @IsString() @MaxLength(40) unit?: string;
  @IsOptional() @IsString() imageBase64?: string;
  @IsOptional() @IsBoolean() isRecurring?: boolean;
  @IsOptional() @IsInt() @Min(1) @Max(3650) recurringDaysManual?: number;
  @IsOptional() @IsDateString() expiryDate?: string;

  @IsOptional()
  @IsObject()
  @ValidateNested()
  @Type(() => InitialPurchaseRequest)
  initialPurchase?: InitialPurchaseRequest;
}

export class UpdateProductRequest {
  @IsOptional() @IsString() @IsNotEmpty() @MaxLength(160) name?: string;
  @IsOptional() @IsIn(CATEGORIES as unknown as string[]) category?: string;
  @IsOptional() @IsString() @MaxLength(40) size?: string;
  @IsOptional() @IsString() @MaxLength(40) unit?: string;
  @IsOptional() @IsString() imageBase64?: string;
  @IsOptional() @IsBoolean() isRecurring?: boolean;
  @IsOptional() @IsInt() @Min(1) @Max(3650) recurringDaysManual?: number;
  @IsOptional() @IsDateString() expiryDate?: string;
  @IsOptional() @IsIn(STATUSES as unknown as string[]) status?: string;
}

export class UpdateStatusRequest {
  @IsIn(STATUSES as unknown as string[]) status: string;
}

export class CreatePurchaseRequest {
  @IsInt() @Min(0) @Max(100000) quantity: number;
  @IsNumber({ maxDecimalPlaces: 2 }) @Min(0) price: number;
  @IsOptional() @IsString() @MaxLength(80) buyer?: string;
  @IsOptional() @IsString() @MaxLength(120) store?: string;
  @IsOptional() @IsDateString() purchasedAt?: string;
}
