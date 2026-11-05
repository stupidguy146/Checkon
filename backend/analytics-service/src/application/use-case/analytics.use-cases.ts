import { Inject, Injectable } from '@nestjs/common';
import { CATALOG_PORT, CatalogPort } from '../../domain/port/catalog.port';

/**
 * Analytics use cases computed from household items (via CatalogPort).
 * - summary: grand total, spend per month (by purchaseDate), by category
 * - expiringSoon: items expiring within N days
 */
@Injectable()
export class AnalyticsUseCases {
  constructor(
    @Inject(CATALOG_PORT)
    private readonly catalog: CatalogPort,
  ) {}

  async summary(ssoId: string) {
    const items = await this.catalog.getAllItems(ssoId);

    let grandTotal = 0;
    const byMonth = new Map<string, number>(); // 'yyyy-mm' → amount
    const byCategory = new Map<string, number>(); // category → amount

    for (const it of items) {
      const sub = it.subtotal();
      grandTotal += sub;
      byCategory.set(it.category, (byCategory.get(it.category) ?? 0) + sub);
      if (it.purchaseDate) {
        const key = it.purchaseDate.slice(0, 7); // yyyy-mm
        byMonth.set(key, (byMonth.get(key) ?? 0) + sub);
      }
    }

    const months = [...byMonth.entries()]
      .map(([month, amount]) => ({ month, amount }))
      .sort((a, b) => a.month.localeCompare(b.month));
    const categories = [...byCategory.entries()]
      .map(([category, amount]) => ({ category, amount }))
      .sort((a, b) => b.amount - a.amount);

    return {
      grandTotal,
      totalItems: items.length,
      months,
      categories,
    };
  }

  /** Monthly summary computed from purchases (not items). */
  async summaryByMonth(ssoId: string, month: string) {
    const [products, purchases] = await Promise.all([
      this.catalog.getProducts(ssoId),
      this.catalog.getPurchasesByMonth(ssoId, month),
    ]);
    const categoryOf = new Map(products.map((p) => [p.productId, p.category]));

    let grandTotal = 0;
    let totalQty = 0;
    const byCategory = new Map<string, number>();
    const byBuyer = new Map<string, number>();

    for (const p of purchases) {
      grandTotal += p.subtotal;
      totalQty += p.quantity;
      const cat = categoryOf.get(p.productId) ?? 'other';
      byCategory.set(cat, (byCategory.get(cat) ?? 0) + p.subtotal);
      const buyer = (p.buyer ?? '').trim() || 'unknown';
      byBuyer.set(buyer, (byBuyer.get(buyer) ?? 0) + p.subtotal);
    }

    return {
      month,
      grandTotal,
      totalPurchases: purchases.length,
      totalQty,
      byCategory: [...byCategory.entries()]
        .map(([category, amount]) => ({ category, amount }))
        .sort((a, b) => b.amount - a.amount),
      byBuyer: [...byBuyer.entries()]
        .map(([buyer, amount]) => ({ buyer, amount }))
        .sort((a, b) => b.amount - a.amount),
    };
  }

  /**
   * Spend per month from purchases, for the last [months] months up to and
   * including the current month (oldest → newest). Same data source as
   * summaryByMonth, so the series and the per-month summary always agree.
   */
  async spendByMonth(ssoId: string, months: number, endMonth?: string) {
    const n = Math.max(1, Math.min(24, Math.floor(months) || 6));
    const [year, month] = endMonth
      ? endMonth.split('-').map(Number)
      : [new Date().getUTCFullYear(), new Date().getUTCMonth() + 1];
    // build the list of yyyy-mm keys, oldest first
    const keys: string[] = [];
    for (let i = n - 1; i >= 0; i--) {
      const d = new Date(Date.UTC(year, month - 1 - i, 1));
      keys.push(d.toISOString().slice(0, 7));
    }
    // fetch each month's purchases in parallel, then total each month
    const perMonth = await Promise.all(
      keys.map((month) => this.catalog.getPurchasesByMonth(ssoId, month)),
    );
    const months_ = keys.map((month, idx) => ({
      month,
      amount: perMonth[idx].reduce((sum, p) => sum + p.subtotal, 0),
    }));
    return { months: months_ };
  }

  async expiringSoon(days: number, ssoId: string) {
    const items = await this.catalog.getAllItems(ssoId);
    const now = new Date();
    const result = items
      .map((it) => ({ it, d: it.daysUntilExpiry(now) }))
      .filter(({ d }) => d !== null && d <= days)
      .map(({ it, d }) => ({
        itemId: it.itemId,
        name: it.name,
        category: it.category,
        quantity: it.quantity,
        expiryDate: it.expiryDate,
        daysUntilExpiry: d,
        imageBase64: it.imageBase64,
        notifyRecurring: it.notifyRecurring,
      }));
    result.sort((a, b) => (a.daysUntilExpiry ?? 0) - (b.daysUntilExpiry ?? 0));
    return { days, count: result.length, items: result };
  }
}
