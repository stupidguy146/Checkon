import { Category } from '../../shared/categories';

export interface CreateItemCommand {
  ssoId: string;
  name: string;
  category: Category;
  size?: string | null;
  unit?: string | null;
  quantity: number;
  price: number;
  store?: string | null;
  purchaseDate?: string | null;
  buyer?: string | null;
  expiryDate?: string | null;
  imageBase64?: string | null;
  notifyRecurring?: boolean;
  recurringDays?: number | null;
}

export interface UpdateItemCommand {
  name?: string;
  category?: Category;
  size?: string | null;
  unit?: string | null;
  quantity?: number;
  price?: number;
  store?: string | null;
  purchaseDate?: string | null;
  buyer?: string | null;
  expiryDate?: string | null;
  imageBase64?: string | null;
  notifyRecurring?: boolean;
  recurringDays?: number | null;
}
