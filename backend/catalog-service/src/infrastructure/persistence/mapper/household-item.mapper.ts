import { HouseholdItem } from '../../../domain/model/household-item';
import { Category } from '../../../shared/categories';
import { HouseholdItemRecord } from '../orm/household-item.persistence';

export class HouseholdItemMapper {
  static toRecord(d: HouseholdItem): HouseholdItemRecord {
    const r = new HouseholdItemRecord();
    if (d.id !== undefined) r.id = d.id;
    r.itemId = d.itemId;
    r.ssoId = d.ssoId;
    r.name = d.name;
    r.category = d.category;
    r.size = d.size;
    r.unit = d.unit;
    r.quantity = d.quantity;
    r.price = d.price.toFixed(2);
    r.store = d.store;
    r.purchaseDate = d.purchaseDate;
    r.buyer = d.buyer;
    r.expiryDate = d.expiryDate;
    r.imageBase64 = d.imageBase64;
    r.notifyRecurring = d.notifyRecurring;
    r.recurringDays = d.recurringDays;
    r.createdAt = d.createdAt;
    return r;
  }

  static toDomain(r: HouseholdItemRecord): HouseholdItem {
    return new HouseholdItem({
      id: r.id,
      itemId: r.itemId,
      ssoId: r.ssoId,
      name: r.name,
      category: r.category as Category,
      size: r.size,
      unit: r.unit,
      quantity: r.quantity,
      price: parseFloat(r.price ?? '0'),
      store: r.store,
      purchaseDate: r.purchaseDate,
      buyer: r.buyer,
      expiryDate: r.expiryDate,
      imageBase64: r.imageBase64,
      notifyRecurring: r.notifyRecurring,
      recurringDays: r.recurringDays ?? null,
      createdAt: r.createdAt,
    });
  }
}
