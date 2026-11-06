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
const currentMonth = () => new Date().toISOString().slice(0, 7);

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
    const activeMonthProducts = await this.productsInUseForMonth(
      ssoId,
      currentMonth(),
    );
    // `out` first (more urgent), then `low`; stable within each group.
    const rank = (s: string) => (s === 'out' ? 0 : s === 'low' ? 1 : 2);
    return activeMonthProducts
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
    if (cmd.status !== undefined) {
      p.status = cmd.status;
      const saved = await this.products.update(p);
      await this.products.saveMonthStatuses(ssoId, currentMonth(), [
        { productId, status: cmd.status },
      ]);
      return saved;
    }
    return this.products.update(p);
  }

  async updateProductStatus(
    productId: string,
    ssoId: string,
    status: Product['status'],
  ): Promise<Product> {
    const product = await this.getProduct(productId, ssoId);
    product.status = status;
    const saved = await this.products.update(product);
    await this.products.saveMonthStatuses(ssoId, currentMonth(), [
      { productId, status },
    ]);
    return saved;
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
    const purchasedAt = cmd.purchasedAt ?? today();
    const saved = await this.purchases.create(
      new Purchase({
        purchaseId: randomUUID(),
        productId: cmd.productId,
        ssoId: cmd.ssoId,
        quantity: cmd.quantity,
        price: cmd.price,
        buyer: cmd.buyer ?? null,
        store: cmd.store ?? null,
        purchasedAt,
        createdAt: new Date(),
      }),
    );
    // Only a purchase in the active month changes live stock state.
    if (purchasedAt.slice(0, 7) === currentMonth()) {
      if (product.status !== 'in_stock') {
        product.status = 'in_stock';
        await this.products.update(product);
      }
      await this.products.saveMonthStatuses(cmd.ssoId, currentMonth(), [
        { productId: product.productId, status: 'in_stock' },
      ]);
    }
    return saved;
  }

  async listPurchasesByMonth(
    ssoId: string,
    month: string,
  ): Promise<Purchase[]> {
    return this.purchases.findByMonth(ssoId, month);
  }

  /** Return the saved monthly log, carrying only stock/low into the active month. */
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

    const purchasesByProduct = new Map<string, Set<string>>();
    const firstMonth = new Map<string, string>();
    const productsById = new Map(products.map((product) => [product.productId, product]));
    for (const purchase of allPurchases) {
      const purchaseMonth = purchase.purchasedAt.slice(0, 7);
      const first = firstMonth.get(purchase.productId);
      if (first === undefined || purchaseMonth < first) {
        firstMonth.set(purchase.productId, purchaseMonth);
      }
      let months = purchasesByProduct.get(purchase.productId);
      if (!months) {
        months = new Set<string>();
        purchasesByProduct.set(purchase.productId, months);
      }
      months.add(purchaseMonth);
    }

    let monthStatuses = await this.products.findMonthStatuses(ssoId, month);
    if (monthStatuses.length === 0) {
      const toSave: Array<{ productId: string; status: string }> = [];
      if (month === currentMonth()) {
        const [year, monthNumber] = month.split('-').map(Number);
        const previousMonth = new Date(
          Date.UTC(year, monthNumber - 2, 1),
        ).toISOString().slice(0, 7);
        let previousStatuses =
          await this.products.findMonthStatuses(ssoId, previousMonth);
        const previousExcluded = new Set(
          await this.products.findExcludedProductIds(ssoId, previousMonth),
        );
        if (previousStatuses.length === 0) {
          previousStatuses = products
            .filter((product) => {
              const first = firstMonth.get(product.productId);
              return (
                !previousExcluded.has(product.productId) &&
                first !== undefined &&
                first <= previousMonth
              );
            })
            .map((product) => ({
              productId: product.productId,
              status: product.status,
            }));
          await this.products.saveMonthStatuses(
            ssoId,
            previousMonth,
            previousStatuses,
          );
        }

        for (const product of products) {
          if (excluded.has(product.productId)) continue;
          const boughtThisMonth =
            purchasesByProduct.get(product.productId)?.has(month) ?? false;
          const previousStatus = previousStatuses.find(
            (entry) => entry.productId === product.productId,
          )?.status;
          if (boughtThisMonth) {
            toSave.push({
              productId: product.productId,
              status: product.status,
            });
          } else if (
            !previousExcluded.has(product.productId) &&
            (previousStatus === 'in_stock' || previousStatus === 'low')
          ) {
            toSave.push({
              productId: product.productId,
              status: previousStatus,
            });
          }
        }
      } else {
        const previousExcluded = new Set(excludedProductIds);
        for (const product of products) {
          const first = firstMonth.get(product.productId);
          if (
            !previousExcluded.has(product.productId) &&
            first !== undefined &&
            first <= month
          ) {
            toSave.push({
              productId: product.productId,
              status: product.status,
            });
          }
        }
      }
      if (month === currentMonth()) {
        await Promise.all(
          toSave.map(async ({ productId, status }) => {
            const product = productsById.get(productId);
            if (product && product.status !== status) {
              product.status = status as Product['status'];
              await this.products.update(product);
            }
          }),
        );
      }
      await this.products.saveMonthStatuses(ssoId, month, toSave);
      monthStatuses = toSave;
    } else if (month === currentMonth()) {
      const knownIds = new Set(monthStatuses.map(({ productId }) => productId));
      const newPurchases = products
        .filter(
          (product) =>
            !excluded.has(product.productId) &&
            !knownIds.has(product.productId) &&
            (purchasesByProduct.get(product.productId)?.has(month) ?? false),
        )
        .map((product) => ({
          productId: product.productId,
          status: product.status,
        }));
      await this.products.saveMonthStatuses(ssoId, month, newPurchases);
      monthStatuses = [...monthStatuses, ...newPurchases];
    }

    return monthStatuses
      .filter(
        ({ productId }) =>
          !excluded.has(productId) && productsById.has(productId),
      )
      .map(({ productId, status }) => {
        const product = productsById.get(productId)!;
        product.status = status as Product['status'];
        return product;
      });
  }
}
