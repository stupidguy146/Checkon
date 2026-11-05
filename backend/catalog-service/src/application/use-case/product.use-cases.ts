import { Inject, Injectable } from '@nestjs/common';
import { randomUUID } from 'crypto';
import {
  PRODUCT_REPOSITORY,
  ProductRepositoryPort,
} from '../../domain/port/product.repository.port';
import {
  PURCHASE_REPOSITORY,
  PurchaseRepositoryPort,
} from '../../domain/port/purchase.repository.port';
import { Product } from '../../domain/model/product';
import { Purchase } from '../../domain/model/purchase';
import { Category } from '../../shared/categories';
import { DomainError, CatalogErrorCode } from '../../shared/errors';
import {
  CreateProductCommand,
  UpdateProductCommand,
  CreatePurchaseCommand,
} from '../dto/product.commands';

const today = () => new Date().toISOString().slice(0, 10);

/** Use-cases for product master + purchases, scoped by owner (ssoId). */
@Injectable()
export class ProductUseCases {
  constructor(
    @Inject(PRODUCT_REPOSITORY)
    private readonly products: ProductRepositoryPort,
    @Inject(PURCHASE_REPOSITORY)
    private readonly purchases: PurchaseRepositoryPort,
  ) {}

  async createProduct(cmd: CreateProductCommand): Promise<Product> {
    const product = new Product({
      productId: randomUUID(),
      ssoId: cmd.ssoId,
      name: cmd.name,
      category: cmd.category,
      size: cmd.size ?? null,
      unit: cmd.unit ?? null,
      imageBase64: cmd.imageBase64 ?? null,
      isRecurring: cmd.isRecurring ?? false,
      recurringDaysManual: cmd.recurringDaysManual ?? null,
      expiryDate: cmd.expiryDate ?? null,
      status: 'in_stock',
      createdAt: new Date(),
    });
    const saved = await this.products.create(product);

    // record the first purchase alongside the product when provided
    if (cmd.initialPurchase) {
      await this.purchases.create(
        new Purchase({
          purchaseId: randomUUID(),
          productId: saved.productId,
          ssoId: cmd.ssoId,
          quantity: cmd.initialPurchase.quantity,
          price: cmd.initialPurchase.price,
          buyer: cmd.initialPurchase.buyer ?? null,
          store: cmd.initialPurchase.store ?? null,
          purchasedAt: cmd.initialPurchase.purchasedAt ?? today(),
          createdAt: new Date(),
        }),
      );
    }
    return saved;
  }

  async listProducts(ssoId: string, category?: Category): Promise<Product[]> {
    return this.products.findAll(ssoId, category);
  }

  /** Products that need restocking — user-driven status `low` or `out`. */
  async productsToBuy(ssoId: string): Promise<Product[]> {
    const all = await this.products.findAll(ssoId);
    // `out` first (more urgent), then `low`; stable within each group.
    const rank = (s: string) => (s === 'out' ? 0 : s === 'low' ? 1 : 2);
    return all
        .filter((p) => p.status === 'low' || p.status === 'out')
        .sort((a, b) => rank(a.status) - rank(b.status));
  }

  async getProduct(productId: string, ssoId: string): Promise<Product> {
    const p = await this.products.findById(productId, ssoId);
    if (!p) throw new DomainError(CatalogErrorCode.PRODUCT_NOT_FOUND);
    return p;
  }

  async getProductHistory(
    productId: string,
    ssoId: string,
  ): Promise<Purchase[]> {
    await this.getProduct(productId, ssoId); // ensure ownership/existence
    return this.purchases.findByProduct(productId, ssoId);
  }

  async updateProduct(
    productId: string,
    ssoId: string,
    cmd: UpdateProductCommand,
  ): Promise<Product> {
    const p = await this.getProduct(productId, ssoId);
    if (cmd.name !== undefined) p.name = cmd.name;
    if (cmd.category !== undefined) p.category = cmd.category;
    if (cmd.size !== undefined) p.size = cmd.size;
    if (cmd.unit !== undefined) p.unit = cmd.unit;
    if (cmd.imageBase64 !== undefined) p.imageBase64 = cmd.imageBase64;
    if (cmd.isRecurring !== undefined) p.isRecurring = cmd.isRecurring;
    if (cmd.recurringDaysManual !== undefined) {
      p.recurringDaysManual = cmd.recurringDaysManual;
    }
    if (cmd.expiryDate !== undefined) p.expiryDate = cmd.expiryDate;
    if (cmd.status !== undefined) p.status = cmd.status;
    return this.products.update(p);
  }

  async deleteProduct(productId: string, ssoId: string): Promise<void> {
    await this.getProduct(productId, ssoId);
    await this.products.delete(productId, ssoId);
  }

  async excludeProductFromMonth(
    productId: string,
    ssoId: string,
    month: string,
  ): Promise<void> {
    await this.getProduct(productId, ssoId);
    await this.products.excludeFromMonth(productId, ssoId, month);
  }

  /** Record a purchase; buying restocks the product (status → in_stock). */
  async createPurchase(cmd: CreatePurchaseCommand): Promise<Purchase> {
    const product = await this.getProduct(cmd.productId, cmd.ssoId);
    const saved = await this.purchases.create(
      new Purchase({
        purchaseId: randomUUID(),
        productId: cmd.productId,
        ssoId: cmd.ssoId,
        quantity: cmd.quantity,
        price: cmd.price,
        buyer: cmd.buyer ?? null,
        store: cmd.store ?? null,
        purchasedAt: cmd.purchasedAt ?? today(),
        createdAt: new Date(),
      }),
    );
    // buying something marks it back in stock
    if (product.status !== 'in_stock') {
      product.status = 'in_stock';
      await this.products.update(product);
    }
    return saved;
  }

  async listPurchasesByMonth(
    ssoId: string,
    month: string,
  ): Promise<Purchase[]> {
    return this.purchases.findByMonth(ssoId, month);
  }

  /**
   * Products "in use" during [month] (yyyy-mm), applying the carry-over rule:
   * a product counts for month M if it has a purchase in M, OR its first
   * purchase is in a month before M and it is still not marked `out` (i.e. it
   * carried over and is still being used). Future months are not considered
   * (callers pass the current month at most).
   */
  async productsInUseForMonth(
    ssoId: string,
    month: string,
  ): Promise<Product[]> {
    const [products, allPurchases, excludedProductIds] = await Promise.all([
      this.products.findAll(ssoId),
      this.purchases.findAllByOwner(ssoId),
      this.products.findExcludedProductIds(ssoId, month),
    ]);
    const excluded = new Set(excludedProductIds);

    // per product: earliest purchase month + the set of months with a purchase
    const firstMonth = new Map<string, string>(); // productId → yyyy-mm
    const monthsWithPurchase = new Map<string, Set<string>>();
    for (const p of allPurchases) {
      const m = p.purchasedAt.slice(0, 7); // yyyy-mm
      const cur = firstMonth.get(p.productId);
      if (cur === undefined || m < cur) firstMonth.set(p.productId, m);
      let set = monthsWithPurchase.get(p.productId);
      if (!set) {
        set = new Set<string>();
        monthsWithPurchase.set(p.productId, set);
      }
      set.add(m);
    }

    return products.filter((prod) => {
      if (excluded.has(prod.productId)) return false;
      const first = firstMonth.get(prod.productId);
      if (first === undefined) return false; // never purchased → not "in use"
      const boughtThisMonth =
        monthsWithPurchase.get(prod.productId)?.has(month) ?? false;
      if (boughtThisMonth) return true;
      // carried over: first purchase before this month AND still not used up
      return first < month && prod.status !== 'out';
    });
  }
}
