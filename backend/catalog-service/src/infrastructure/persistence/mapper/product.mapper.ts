import { Product, ProductStatus } from '../../../domain/model/product';
import { Category } from '../../../shared/categories';
import { ProductRecord } from '../orm/product.persistence';

export class ProductMapper {
  static toRecord(d: Product): ProductRecord {
    const r = new ProductRecord();
    if (d.id !== undefined) r.id = d.id;
    r.productId = d.productId;
    r.ssoId = d.ssoId;
    r.name = d.name;
    r.category = d.category;
    r.size = d.size;
    r.unit = d.unit;
    r.imageBase64 = d.imageBase64;
    r.isRecurring = d.isRecurring;
    r.recurringDaysManual = d.recurringDaysManual;
    r.expiryDate = d.expiryDate;
    r.status = d.status;
    r.createdAt = d.createdAt;
    return r;
  }

  static toDomain(r: ProductRecord): Product {
    return new Product({
      id: r.id,
      productId: r.productId,
      ssoId: r.ssoId,
      name: r.name,
      category: r.category as Category,
      size: r.size,
      unit: r.unit,
      imageBase64: r.imageBase64,
      isRecurring: r.isRecurring,
      recurringDaysManual: r.recurringDaysManual ?? null,
      expiryDate: r.expiryDate,
      status: (r.status as ProductStatus) ?? 'in_stock',
      createdAt: r.createdAt,
    });
  }
}
