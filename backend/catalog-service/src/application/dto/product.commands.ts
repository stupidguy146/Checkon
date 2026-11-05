import { Category } from '../../shared/categories';
import { ProductStatus } from '../../domain/model/product';

export interface CreateProductCommand {
  ssoId: string;
  name: string;
  category: Category;
  size?: string | null;
  unit?: string | null;
  imageBase64?: string | null;
  isRecurring?: boolean;
  recurringDaysManual?: number | null;
  expiryDate?: string | null;
  // optional first purchase recorded together with the product
  initialPurchase?: {
    quantity: number;
    price: number;
    buyer?: string | null;
    store?: string | null;
    purchasedAt?: string | null; // defaults to today
  } | null;
}

export interface UpdateProductCommand {
  name?: string;
  category?: Category;
  size?: string | null;
  unit?: string | null;
  imageBase64?: string | null;
  isRecurring?: boolean;
  recurringDaysManual?: number | null;
  expiryDate?: string | null;
  status?: ProductStatus;
}

export interface CreatePurchaseCommand {
  ssoId: string;
  productId: string;
  quantity: number;
  price: number;
  buyer?: string | null;
  store?: string | null;
  purchasedAt?: string | null; // defaults to today
}
