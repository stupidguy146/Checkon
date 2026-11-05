import { Category } from '../../shared/categories';

/**
 * Domain model for a household consumable item. Owned by a user (ssoId).
 * Pure TypeScript — no framework/ORM dependency.
 */
export interface HouseholdItemProps {
  id?: number; // running PK (assigned by DB)
  itemId: string; // public UUID
  ssoId: string;
  name: string;
  category: Category;
  size: string | null; // e.g. "1.5"
  unit: string | null; // e.g. "ลิตร"
  quantity: number;
  price: number;
  store: string | null;
  purchaseDate: string | null; // ISO yyyy-mm-dd
  buyer: string | null;
  expiryDate: string | null; // ISO yyyy-mm-dd
  imageBase64: string | null;
  notifyRecurring: boolean;
  recurringDays: number | null; // consumption cycle in days (recurring items)
  createdAt: Date;
}

export class HouseholdItem {
  readonly id?: number;
  readonly itemId: string;
  readonly ssoId: string;
  name: string;
  category: Category;
  size: string | null;
  unit: string | null;
  quantity: number;
  price: number;
  store: string | null;
  purchaseDate: string | null;
  buyer: string | null;
  expiryDate: string | null;
  imageBase64: string | null;
  notifyRecurring: boolean;
  recurringDays: number | null;
  readonly createdAt: Date;

  constructor(p: HouseholdItemProps) {
    this.id = p.id;
    this.itemId = p.itemId;
    this.ssoId = p.ssoId;
    this.name = p.name;
    this.category = p.category;
    this.size = p.size;
    this.unit = p.unit;
    this.quantity = p.quantity;
    this.price = p.price;
    this.store = p.store;
    this.purchaseDate = p.purchaseDate;
    this.buyer = p.buyer;
    this.expiryDate = p.expiryDate;
    this.imageBase64 = p.imageBase64;
    this.notifyRecurring = p.notifyRecurring;
    this.recurringDays = p.recurringDays;
    this.createdAt = p.createdAt;
  }

  /** days until expiry (null if no expiry date) relative to `now`. */
  daysUntilExpiry(now = new Date()): number | null {
    if (!this.expiryDate) return null;
    const exp = new Date(this.expiryDate);
    const ms = exp.getTime() - new Date(now.toISOString().slice(0, 10)).getTime();
    return Math.round(ms / 86400000);
  }

  /** subtotal = price × quantity */
  subtotal(): number {
    return this.price * this.quantity;
  }
}
