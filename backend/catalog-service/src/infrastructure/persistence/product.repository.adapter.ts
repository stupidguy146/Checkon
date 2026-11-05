import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { ProductRepositoryPort } from '../../domain/port/product.repository.port';
import { Product } from '../../domain/model/product';
import { Category } from '../../shared/categories';
import { ProductRecord } from './orm/product.persistence';
import { ProductMonthExclusionRecord } from './orm/product-month-exclusion.persistence';
import { ProductMapper } from './mapper/product.mapper';

@Injectable()
export class ProductRepositoryAdapter implements ProductRepositoryPort {
  constructor(
    @InjectRepository(ProductRecord)
    private readonly products: Repository<ProductRecord>,
    @InjectRepository(ProductMonthExclusionRecord)
    private readonly monthExclusions: Repository<ProductMonthExclusionRecord>,
  ) {}

  async create(product: Product): Promise<Product> {
    const saved = await this.products.save(ProductMapper.toRecord(product));
    return ProductMapper.toDomain(saved);
  }

  async findAll(ssoId: string, category?: Category): Promise<Product[]> {
    const rows = await this.products.find({
      where: category ? { ssoId, category } : { ssoId },
      order: { createdAt: 'DESC' },
    });
    return rows.map((r) => ProductMapper.toDomain(r));
  }

  async findById(productId: string, ssoId: string): Promise<Product | null> {
    const row = await this.products.findOne({ where: { productId, ssoId } });
    return row ? ProductMapper.toDomain(row) : null;
  }

  async update(product: Product): Promise<Product> {
    const record = ProductMapper.toRecord(product);
    if (record.id === undefined) {
      const existing = await this.products.findOne({
        where: { productId: product.productId, ssoId: product.ssoId },
        select: { id: true },
      });
      if (existing) record.id = existing.id;
    }
    const saved = await this.products.save(record);
    return ProductMapper.toDomain(saved);
  }

  async delete(productId: string, ssoId: string): Promise<void> {
    await this.monthExclusions.delete({ productId, ssoId });
    await this.products.delete({ productId, ssoId });
  }

  async excludeFromMonth(
    productId: string,
    ssoId: string,
    month: string,
  ): Promise<void> {
    await this.monthExclusions.upsert(
      { productId, ssoId, month },
      ['ssoId', 'productId', 'month'],
    );
  }

  async findExcludedProductIds(ssoId: string, month: string): Promise<string[]> {
    const records = await this.monthExclusions.find({
      where: { ssoId, month },
      select: { productId: true },
    });
    return records.map((record) => record.productId);
  }

  async count(ssoId: string): Promise<number> {
    return this.products.count({ where: { ssoId } });
  }
}
