import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';
import { CatalogModule } from './catalog.module';
import { HouseholdItemRecord } from './infrastructure/persistence/orm/household-item.persistence';
import { ProductRecord } from './infrastructure/persistence/orm/product.persistence';
import { PurchaseRecord } from './infrastructure/persistence/orm/purchase.persistence';
import { ProductMonthExclusionRecord } from './infrastructure/persistence/orm/product-month-exclusion.persistence';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    TypeOrmModule.forRootAsync({
      inject: [ConfigService],
      useFactory: (config: ConfigService) => ({
        type: 'postgres',
        host: config.get<string>('DB_HOST', 'localhost'),
        port: parseInt(config.get<string>('DB_PORT', '5433'), 10),
        username: config.get<string>('DB_USER', 'catalog'),
        password: config.get<string>('DB_PASSWORD', 'catalog_pass'),
        database: config.get<string>('DB_NAME', 'catalog_db'),
        entities: [
          HouseholdItemRecord,
          ProductRecord,
          PurchaseRecord,
          ProductMonthExclusionRecord,
        ],
        synchronize: true, // dev only
      }),
    }),
    CatalogModule,
  ],
})
export class AppModule {}
