import { Inject, Injectable } from '@nestjs/common';
import { randomUUID } from 'crypto';
import {
  ITEM_REPOSITORY,
  ItemRepositoryPort,
} from '../../domain/port/item.repository.port';
import { HouseholdItem } from '../../domain/model/household-item';
import { Category } from '../../shared/categories';
import { DomainError, CatalogErrorCode } from '../../shared/errors';
import { CreateItemCommand, UpdateItemCommand } from '../dto/commands';

/** Application use-cases for household items, scoped by owner (ssoId). */
@Injectable()
export class ItemUseCases {
  constructor(
    @Inject(ITEM_REPOSITORY)
    private readonly repo: ItemRepositoryPort,
  ) {}

  async create(cmd: CreateItemCommand): Promise<HouseholdItem> {
    const purchaseDate = cmd.purchaseDate ?? null;
    const recurringDays = cmd.recurringDays ?? null;
    const expiryDate = this.resolveExpiryDate(
      cmd.expiryDate ?? null,
      cmd.notifyRecurring ?? false,
      recurringDays,
      purchaseDate,
    );
    const item = new HouseholdItem({
      itemId: randomUUID(),
      ssoId: cmd.ssoId,
      name: cmd.name,
      category: cmd.category,
      size: cmd.size ?? null,
      unit: cmd.unit ?? null,
      quantity: cmd.quantity,
      price: cmd.price,
      store: cmd.store ?? null,
      purchaseDate,
      buyer: cmd.buyer ?? null,
      expiryDate,
      imageBase64: cmd.imageBase64 ?? null,
      notifyRecurring: cmd.notifyRecurring ?? false,
      recurringDays,
      createdAt: new Date(),
    });
    return this.repo.create(item);
  }

  /**
   * For recurring items the user doesn't have to enter an expiry date — we
   * derive it as (purchaseDate or today) + recurringDays. The user's own
   * expiry date always wins when provided.
   */
  private resolveExpiryDate(
    userExpiry: string | null,
    notifyRecurring: boolean,
    recurringDays: number | null,
    purchaseDate: string | null,
  ): string | null {
    if (userExpiry) return userExpiry; // user value always wins
    if (!notifyRecurring || !recurringDays || recurringDays <= 0) {
      return null;
    }
    const base = purchaseDate
      ? new Date(purchaseDate)
      : new Date(new Date().toISOString().slice(0, 10));
    if (isNaN(base.getTime())) return null;
    base.setDate(base.getDate() + recurringDays);
    return base.toISOString().slice(0, 10); // yyyy-mm-dd
  }

  async list(ssoId: string, category?: Category): Promise<HouseholdItem[]> {
    return this.repo.findAll(ssoId, category);
  }

  async getById(itemId: string, ssoId: string): Promise<HouseholdItem> {
    const item = await this.repo.findById(itemId, ssoId);
    if (!item) throw new DomainError(CatalogErrorCode.ITEM_NOT_FOUND);
    return item;
  }

  async update(
    itemId: string,
    ssoId: string,
    cmd: UpdateItemCommand,
  ): Promise<HouseholdItem> {
    const item = await this.getById(itemId, ssoId);
    if (cmd.name !== undefined) item.name = cmd.name;
    if (cmd.category !== undefined) item.category = cmd.category;
    if (cmd.size !== undefined) item.size = cmd.size;
    if (cmd.unit !== undefined) item.unit = cmd.unit;
    if (cmd.quantity !== undefined) item.quantity = cmd.quantity;
    if (cmd.price !== undefined) item.price = cmd.price;
    if (cmd.store !== undefined) item.store = cmd.store;
    if (cmd.purchaseDate !== undefined) item.purchaseDate = cmd.purchaseDate;
    if (cmd.buyer !== undefined) item.buyer = cmd.buyer;
    if (cmd.expiryDate !== undefined) item.expiryDate = cmd.expiryDate;
    if (cmd.imageBase64 !== undefined) item.imageBase64 = cmd.imageBase64;
    if (cmd.notifyRecurring !== undefined) {
      item.notifyRecurring = cmd.notifyRecurring;
    }
    if (cmd.recurringDays !== undefined) {
      item.recurringDays = cmd.recurringDays;
    }
    // Recompute expiry for recurring items when the user hasn't set one. The
    // user's explicit expiry date (if provided in this update) always wins.
    if (cmd.expiryDate === undefined || cmd.expiryDate === null) {
      const resolved = this.resolveExpiryDate(
        cmd.expiryDate ?? null,
        item.notifyRecurring,
        item.recurringDays,
        item.purchaseDate,
      );
      if (resolved) item.expiryDate = resolved;
    }
    return this.repo.update(item);
  }

  async delete(itemId: string, ssoId: string): Promise<void> {
    await this.getById(itemId, ssoId);
    await this.repo.delete(itemId, ssoId);
  }
}
