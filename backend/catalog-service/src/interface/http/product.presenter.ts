import { Product } from '../../domain/model/product';
import { Purchase } from '../../domain/model/purchase';

/** Converts domain product/purchase into HTTP JSON shapes. */
export class ProductPresenter {
  static product(p: Product) {
    return {
      id: p.id,
      productId: p.productId,
      name: p.name,
      category: p.category,
      size: p.size,
      unit: p.unit,
      imageBase64: p.imageBase64,
      isRecurring: p.isRecurring,
      recurringDaysManual: p.recurringDaysManual,
      expiryDate: p.expiryDate,
      daysUntilExpiry: p.daysUntilExpiry(),
      status: p.status,
      createdAt: p.createdAt,
    };
  }

  static purchase(p: Purchase) {
    return {
      id: p.id,
      purchaseId: p.purchaseId,
      productId: p.productId,
      quantity: p.quantity,
      price: p.price,
      subtotal: p.subtotal(),
      buyer: p.buyer,
      store: p.store,
      purchasedAt: p.purchasedAt,
      createdAt: p.createdAt,
    };
  }
}
