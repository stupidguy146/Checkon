import {
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  Param,
  Patch,
  Post,
  Query,
  Req,
  UseGuards,
} from '@nestjs/common';
import { Request } from 'express';
import { ProxyService } from '../proxy/proxy.service';
import { JwtVerifyGuard } from './jwt-verify.guard';
import { SSO_ID_HEADER } from '../shared/constants';

/**
 * Gateway controller: /api/catalog/items → catalog-service household items.
 * Protected by JWT; forwards the verified user as `x-sso-id`.
 */
@Controller('api/catalog')
@UseGuards(JwtVerifyGuard)
export class CatalogProxyController {
  constructor(private readonly proxy: ProxyService) {}

  private sso(req: Request): Record<string, string> {
    return { [SSO_ID_HEADER]: (req as Request & { ssoId: string }).ssoId };
  }

  @Post('items')
  create(@Req() req: Request, @Body() body: unknown) {
    return this.proxy.forwardToCatalog(
      'POST',
      '/catalog/items',
      body,
      undefined,
      this.sso(req),
    );
  }

  @Get('items')
  list(@Req() req: Request, @Query('category') category?: string) {
    return this.proxy.forwardToCatalog(
      'GET',
      '/catalog/items',
      undefined,
      { category },
      this.sso(req),
    );
  }

  @Get('items/:itemId')
  getOne(@Req() req: Request, @Param('itemId') itemId: string) {
    return this.proxy.forwardToCatalog(
      'GET',
      `/catalog/items/${itemId}`,
      undefined,
      undefined,
      this.sso(req),
    );
  }

  @Patch('items/:itemId')
  update(
    @Req() req: Request,
    @Param('itemId') itemId: string,
    @Body() body: unknown,
  ) {
    return this.proxy.forwardToCatalog(
      'PATCH',
      `/catalog/items/${itemId}`,
      body,
      undefined,
      this.sso(req),
    );
  }

  @Delete('items/:itemId')
  @HttpCode(204)
  remove(@Req() req: Request, @Param('itemId') itemId: string) {
    return this.proxy.forwardToCatalog(
      'DELETE',
      `/catalog/items/${itemId}`,
      undefined,
      undefined,
      this.sso(req),
    );
  }

  // ---------- Products (master) ----------
  @Post('products')
  createProduct(@Req() req: Request, @Body() body: unknown) {
    return this.proxy.forwardToCatalog(
      'POST',
      '/catalog/products',
      body,
      undefined,
      this.sso(req),
    );
  }

  @Get('products')
  listProducts(@Req() req: Request, @Query('category') category?: string) {
    return this.proxy.forwardToCatalog(
      'GET',
      '/catalog/products',
      undefined,
      { category },
      this.sso(req),
    );
  }

  @Get('products/to-buy')
  productsToBuy(@Req() req: Request) {
    return this.proxy.forwardToCatalog(
      'GET',
      '/catalog/products/to-buy',
      undefined,
      undefined,
      this.sso(req),
    );
  }

  @Get('products/by-month')
  productsByMonth(@Req() req: Request, @Query('month') month?: string) {
    return this.proxy.forwardToCatalog(
      'GET',
      '/catalog/products/by-month',
      undefined,
      { month },
      this.sso(req),
    );
  }

  @Get('products/:productId')
  getProduct(@Req() req: Request, @Param('productId') productId: string) {
    return this.proxy.forwardToCatalog(
      'GET',
      `/catalog/products/${productId}`,
      undefined,
      undefined,
      this.sso(req),
    );
  }

  @Get('products/:productId/history')
  productHistory(
    @Req() req: Request,
    @Param('productId') productId: string,
  ) {
    return this.proxy.forwardToCatalog(
      'GET',
      `/catalog/products/${productId}/history`,
      undefined,
      undefined,
      this.sso(req),
    );
  }

  @Patch('products/:productId')
  updateProduct(
    @Req() req: Request,
    @Param('productId') productId: string,
    @Body() body: unknown,
  ) {
    return this.proxy.forwardToCatalog(
      'PATCH',
      `/catalog/products/${productId}`,
      body,
      undefined,
      this.sso(req),
    );
  }

  @Patch('products/:productId/status')
  updateProductStatus(
    @Req() req: Request,
    @Param('productId') productId: string,
    @Body() body: unknown,
    @Query('month') month?: string,
  ) {
    return this.proxy.forwardToCatalog(
      'PATCH',
      `/catalog/products/${productId}/status`,
      body,
      { month },
      this.sso(req),
    );
  }

  @Delete('products/:productId')
  @HttpCode(204)
  removeProduct(@Req() req: Request, @Param('productId') productId: string) {
    return this.proxy.forwardToCatalog(
      'DELETE',
      `/catalog/products/${productId}`,
      undefined,
      undefined,
      this.sso(req),
    );
  }

  @Delete('products/:productId/month')
  @HttpCode(204)
  removeProductFromMonth(
    @Req() req: Request,
    @Param('productId') productId: string,
    @Query('month') month?: string,
  ) {
    return this.proxy.forwardToCatalog(
      'DELETE',
      `/catalog/products/${productId}/month`,
      undefined,
      { month },
      this.sso(req),
    );
  }

  @Post('products/:productId/purchases')
  addPurchase(
    @Req() req: Request,
    @Param('productId') productId: string,
    @Body() body: unknown,
  ) {
    return this.proxy.forwardToCatalog(
      'POST',
      `/catalog/products/${productId}/purchases`,
      body,
      undefined,
      this.sso(req),
    );
  }

  @Get('purchases')
  purchasesByMonth(@Req() req: Request, @Query('month') month?: string) {
    return this.proxy.forwardToCatalog(
      'GET',
      '/catalog/purchases',
      undefined,
      { month },
      this.sso(req),
    );
  }
}
