import {
  BadRequestException,
  Body,
  Controller,
  Delete,
  Get,
  Headers,
  HttpCode,
  Param,
  Patch,
  Post,
  Query,
} from '@nestjs/common';
import { ProductUseCases } from '../../application/use-case/product.use-cases';
import {
  CreateProductRequest,
  UpdateProductRequest,
  UpdateStatusRequest,
  CreatePurchaseRequest,
} from './request/product.requests';
import { ProductPresenter } from './product.presenter';
import { DomainError, CatalogErrorCode } from '../../shared/errors';
import { SSO_ID_HEADER } from '../../shared/constants';
import { Category, isCategory } from '../../shared/categories';
import { ProductStatus } from '../../domain/model/product';

function requireSsoId(ssoId?: string): string {
  if (!ssoId) throw new DomainError(CatalogErrorCode.MISSING_SSO_ID);
  return ssoId;
}

/**
 * Product master + purchases, under the 'products' prefix.
 *   POST   /products                      create product (+ optional first purchase)
 *   GET    /products?category=            list master
 *   GET    /products/:id                  one product
 *   GET    /products/:id/history          purchase history
 *   PATCH  /products/:id                  update master
 *   PATCH  /products/:id/status           change stock status
 *   DELETE /products/:id                  delete
 *   POST   /products/:id/purchases        record a purchase
 *   GET    /purchases?month=YYYY-MM        monthly purchases
 */
@Controller()
export class ProductController {
  constructor(private readonly products: ProductUseCases) {}

  @Post('products')
  async create(
    @Headers(SSO_ID_HEADER) ssoId: string,
    @Body() body: CreateProductRequest,
  ) {
    const product = await this.products.createProduct({
      ssoId: requireSsoId(ssoId),
      ...body,
      category: body.category as Category,
    });
    return ProductPresenter.product(product);
  }

  @Get('products')
  async list(
    @Headers(SSO_ID_HEADER) ssoId: string,
    @Query('category') category?: string,
  ) {
    const cat = isCategory(category) ? category : undefined;
    const list = await this.products.listProducts(requireSsoId(ssoId), cat);
    return list.map((p) => ProductPresenter.product(p));
  }

  @Get('products/to-buy')
  async toBuy(@Headers(SSO_ID_HEADER) ssoId: string) {
    const list = await this.products.productsToBuy(requireSsoId(ssoId));
    return list.map((p) => ProductPresenter.product(p));
  }

  @Get('products/by-month')
  async byMonth(
    @Headers(SSO_ID_HEADER) ssoId: string,
    @Query('month') month?: string,
  ) {
    const m = month && /^\d{4}-\d{2}$/.test(month)
      ? month
      : new Date().toISOString().slice(0, 7);
    const list = await this.products.productsInUseForMonth(
      requireSsoId(ssoId),
      m,
    );
    return list.map((p) => ProductPresenter.product(p));
  }

  @Get('products/:productId')
  async getOne(
    @Headers(SSO_ID_HEADER) ssoId: string,
    @Param('productId') productId: string,
  ) {
    const product = await this.products.getProduct(
      productId,
      requireSsoId(ssoId),
    );
    return ProductPresenter.product(product);
  }

  @Get('products/:productId/history')
  async history(
    @Headers(SSO_ID_HEADER) ssoId: string,
    @Param('productId') productId: string,
  ) {
    const list = await this.products.getProductHistory(
      productId,
      requireSsoId(ssoId),
    );
    return list.map((p) => ProductPresenter.purchase(p));
  }

  @Patch('products/:productId')
  async update(
    @Headers(SSO_ID_HEADER) ssoId: string,
    @Param('productId') productId: string,
    @Body() body: UpdateProductRequest,
  ) {
    const product = await this.products.updateProduct(
      productId,
      requireSsoId(ssoId),
      {
        ...body,
        category: body.category as Category | undefined,
        status: body.status as ProductStatus | undefined,
      },
    );
    return ProductPresenter.product(product);
  }

  @Patch('products/:productId/status')
  async updateStatus(
    @Headers(SSO_ID_HEADER) ssoId: string,
    @Param('productId') productId: string,
    @Body() body: UpdateStatusRequest,
  ) {
    const product = await this.products.updateProduct(
      productId,
      requireSsoId(ssoId),
      { status: body.status as ProductStatus },
    );
    return ProductPresenter.product(product);
  }

  @Delete('products/:productId')
  @HttpCode(204)
  async remove(
    @Headers(SSO_ID_HEADER) ssoId: string,
    @Param('productId') productId: string,
  ) {
    await this.products.deleteProduct(productId, requireSsoId(ssoId));
  }

  @Delete('products/:productId/month')
  @HttpCode(204)
  async removeFromMonth(
    @Headers(SSO_ID_HEADER) ssoId: string,
    @Param('productId') productId: string,
    @Query('month') month?: string,
  ) {
    if (!month || !/^\d{4}-(0[1-9]|1[0-2])$/.test(month)) {
      throw new BadRequestException('month must be in YYYY-MM format');
    }
    await this.products.excludeProductFromMonth(
      productId,
      requireSsoId(ssoId),
      month,
    );
  }

  @Post('products/:productId/purchases')
  async addPurchase(
    @Headers(SSO_ID_HEADER) ssoId: string,
    @Param('productId') productId: string,
    @Body() body: CreatePurchaseRequest,
  ) {
    const purchase = await this.products.createPurchase({
      ssoId: requireSsoId(ssoId),
      productId,
      ...body,
    });
    return ProductPresenter.purchase(purchase);
  }

  @Get('purchases')
  async purchasesByMonth(
    @Headers(SSO_ID_HEADER) ssoId: string,
    @Query('month') month?: string,
  ) {
    const m = month && /^\d{4}-\d{2}$/.test(month)
      ? month
      : new Date().toISOString().slice(0, 7);
    const list = await this.products.listPurchasesByMonth(
      requireSsoId(ssoId),
      m,
    );
    return { month: m, count: list.length, items: list.map((p) => ProductPresenter.purchase(p)) };
  }
}
