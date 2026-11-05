import { Purchase } from '../model/purchase';

/** Outbound port for purchases, scoped by owner (ssoId). */
export interface PurchaseRepositoryPort {
  create(purchase: Purchase): Promise<Purchase>;
  /** all purchases for a product (newest created first) — for purchase history. */
  findByProduct(productId: string, ssoId: string): Promise<Purchase[]>;
  /** purchases within a month (yyyy-mm) for the owner. */
  findByMonth(ssoId: string, month: string): Promise<Purchase[]>;
  /** all purchases for the owner (oldest→newest) — for in-use-by-month calc. */
  findAllByOwner(ssoId: string): Promise<Purchase[]>;
}

export const PURCHASE_REPOSITORY = Symbol('PURCHASE_REPOSITORY');
