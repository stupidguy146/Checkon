import { Injectable, Logger, OnModuleInit } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { randomUUID } from 'crypto';
import { HouseholdItemRecord } from './orm/household-item.persistence';
import { ProductRecord } from './orm/product.persistence';
import { PurchaseRecord } from './orm/purchase.persistence';

/**
 * One-time migration: convert legacy `household_items` rows into the new
 * Product master (+ a first Purchase when the item had purchase info).
 *
 * Idempotent: a product remembers the item it came from via `sourceItemId`,
 * so re-running skips already-migrated items. Safe to run on every boot.
 */
@Injectable()
export class ItemToProductMigration implements OnModuleInit {
  private readonly logger = new Logger(ItemToProductMigration.name);

  constructor(
    @InjectRepository(HouseholdItemRecord)
    private readonly items: Repository<HouseholdItemRecord>,
    @InjectRepository(ProductRecord)
    private readonly products: Repository<ProductRecord>,
    @InjectRepository(PurchaseRecord)
    private readonly purchases: Repository<PurchaseRecord>,
  ) {}

  async onModuleInit(): Promise<void> {
    try {
      await this.run();
    } catch (err: any) {
      // never block startup on migration issues; log and continue
      this.logger.error(`migration skipped: ${err?.message ?? err}`);
    }
  }

  private async run(): Promise<void> {
    const items = await this.items.find();
    if (items.length === 0) return;

    // which legacy items already have a product?
    const migrated = await this.products
      .createQueryBuilder('p')
      .select('p.sourceItemId', 'sourceItemId')
      .where('p.sourceItemId IS NOT NULL')
      .getRawMany<{ sourceItemId: string }>();
    const done = new Set(migrated.map((m) => m.sourceItemId));

    let created = 0;
    for (const it of items) {
      if (done.has(it.itemId)) continue;

      const productId = randomUUID();
      const product = this.products.create({
        productId,
        ssoId: it.ssoId,
        name: it.name,
        category: it.category,
        size: it.size,
        unit: it.unit,
        imageBase64: it.imageBase64,
        isRecurring: it.notifyRecurring ?? false,
        recurringDaysManual: it.recurringDays ?? null,
        expiryDate: it.expiryDate,
        status: (it.quantity ?? 0) <= 0 ? 'out' : 'in_stock',
        sourceItemId: it.itemId,
        createdAt: it.createdAt ?? new Date(),
      });
      await this.products.save(product);

      // seed a first purchase from the item's purchase info when meaningful
      if ((it.quantity ?? 0) > 0 || it.purchaseDate) {
        const purchase = this.purchases.create({
          purchaseId: randomUUID(),
          productId,
          ssoId: it.ssoId,
          quantity: it.quantity ?? 1,
          price: it.price ?? '0',
          buyer: it.buyer,
          store: it.store,
          purchasedAt:
            it.purchaseDate ?? new Date().toISOString().slice(0, 10),
          createdAt: it.createdAt ?? new Date(),
        });
        await this.purchases.save(purchase);
      }
      created++;
    }
    if (created > 0) {
      this.logger.log(`migrated ${created} legacy item(s) → product(s)`);
    }
  }
}
