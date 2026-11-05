import { Category } from '../../shared/categories';

export type ProductStatus = 'in_stock' | 'low' | 'out';

/**
 * Product master — the durable catalogue of things an account owns. Size/unit
 * live here (if they change, it's effectively a different product). The
 * recurring flag lives here and nowhere else. Pure TypeScript.
 */
export interface ProductProps {
  id?: number;
  productId: string;
  ssoId: string;
  name: string;
  category: Category;
  size: string | null;
  unit: string | null;
  imageBase64: string | null;
  isRecurring: boolean;
  recurringDaysManual: number | null; // fallback cycle when stats insufficient
  expiryDate: string | null; // yyyy-mm-dd, for non-recurring perishables
  status: ProductStatus;
  createdAt: Date;
}

export class Product {
  readonly id?: number;
  readonly productId: string;
  readonly ssoId: string;
  name: string;
  category: Category;
  size: string | null;
  unit: string | null;
  imageBase64: string | null;
  isRecurring: boolean;
  recurringDaysManual: number | null;
  expiryDate: string | null;
  status: ProductStatus;
  readonly createdAt: Date;

  constructor(p: ProductProps) {
    this.id = p.id;
    this.productId = p.productId;
    this.ssoId = p.ssoId;
    this.name = p.name;
    this.category = p.category;
    this.size = p.size;
    this.unit = p.unit;
    this.imageBase64 = p.imageBase64;
    this.isRecurring = p.isRecurring;
    this.recurringDaysManual = p.recurringDaysManual;
    this.expiryDate = p.expiryDate;
    this.status = p.status;
    this.createdAt = p.createdAt;
  }

  /** days until expiry (null if no expiry date) relative to `now`. */
  daysUntilExpiry(now = new Date()): number | null {
    if (!this.expiryDate) return null;
    const exp = new Date(this.expiryDate);
    const ms =
      exp.getTime() - new Date(now.toISOString().slice(0, 10)).getTime();
    return Math.round(ms / 86400000);
  }
}
