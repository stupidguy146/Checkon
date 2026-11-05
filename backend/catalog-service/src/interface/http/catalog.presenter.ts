import { HouseholdItem } from '../../domain/model/household-item';

/** Converts the domain item into the HTTP JSON shape. */
export class CatalogPresenter {
  static item(i: HouseholdItem) {
    return {
      id: i.id,
      itemId: i.itemId,
      name: i.name,
      category: i.category,
      size: i.size,
      unit: i.unit,
      quantity: i.quantity,
      price: i.price,
      subtotal: i.subtotal(),
      store: i.store,
      purchaseDate: i.purchaseDate,
      buyer: i.buyer,
      expiryDate: i.expiryDate,
      daysUntilExpiry: i.daysUntilExpiry(),
      imageBase64: i.imageBase64,
      notifyRecurring: i.notifyRecurring,
      recurringDays: i.recurringDays,
      createdAt: i.createdAt,
    };
  }
}
