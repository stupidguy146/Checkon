import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { HouseholdItemRecord } from './infrastructure/persistence/orm/household-item.persistence';
import { ProductRecord } from './infrastructure/persistence/orm/product.persistence';
import { PurchaseRecord } from './infrastructure/persistence/orm/purchase.persistence';
import { ProductMonthExclusionRecord } from './infrastructure/persistence/orm/product-month-exclusion.persistence';
import { ItemRepositoryAdapter } from './infrastructure/persistence/item.repository.adapter';
import { ProductRepositoryAdapter } from './infrastructure/persistence/product.repository.adapter';
import { PurchaseRepositoryAdapter } from './infrastructure/persistence/purchase.repository.adapter';
import { ItemToProductMigration } from './infrastructure/persistence/item-to-product.migration';
import { ITEM_REPOSITORY } from './domain/port/item.repository.port';
import { PRODUCT_REPOSITORY } from './domain/port/product.repository.port';
import { PURCHASE_REPOSITORY } from './domain/port/purchase.repository.port';
import { ItemUseCases } from './application/use-case/item.use-cases';
import { ProductUseCases } from './application/use-case/product.use-cases';
import { ItemController } from './interface/http/catalog.controller';
import { ProductController } from './interface/http/product.controller';

@Module({
  imports: [
    TypeOrmModule.forFeature([
      HouseholdItemRecord,
      ProductRecord,
      PurchaseRecord,
      ProductMonthExclusionRecord,
    ]),
  ],
  controllers: [ItemController, ProductController],
  providers: [
    ItemUseCases,
    ProductUseCases,
    ItemToProductMigration,
    { provide: ITEM_REPOSITORY, useClass: ItemRepositoryAdapter },
    { provide: PRODUCT_REPOSITORY, useClass: ProductRepositoryAdapter },
    { provide: PURCHASE_REPOSITORY, useClass: PurchaseRepositoryAdapter },
  ],
})
export class CatalogModule {}
