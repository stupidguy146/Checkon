import { Controller, Get, Query, Req, UseGuards } from '@nestjs/common';
import { Request } from 'express';
import { ProxyService } from '../proxy/proxy.service';
import { JwtVerifyGuard } from './jwt-verify.guard';
import { SSO_ID_HEADER } from '../shared/constants';

/**
 * Gateway controller: /api/analytics → analytics-service.
 * Protected by JWT; forwards the verified user as `x-sso-id`.
 */
@Controller('api/analytics')
@UseGuards(JwtVerifyGuard)
export class AnalyticsProxyController {
  constructor(private readonly proxy: ProxyService) {}

  private sso(req: Request): Record<string, string> {
    return { [SSO_ID_HEADER]: (req as Request & { ssoId: string }).ssoId };
  }

  @Get('summary')
  summary(@Req() req: Request) {
    return this.proxy.forwardToAnalytics(
      'GET',
      '/analytics/summary',
      undefined,
      undefined,
      this.sso(req),
    );
  }

  @Get('summary-month')
  summaryByMonth(@Req() req: Request, @Query('month') month?: string) {
    return this.proxy.forwardToAnalytics(
      'GET',
      '/analytics/summary-month',
      undefined,
      { month },
      this.sso(req),
    );
  }

  @Get('spend-by-month')
  spendByMonth(
    @Req() req: Request,
    @Query('months') months?: string,
    @Query('month') month?: string,
  ) {
    return this.proxy.forwardToAnalytics(
      'GET',
      '/analytics/spend-by-month',
      undefined,
      { months, month },
      this.sso(req),
    );
  }

  @Get('expiring-soon')
  expiringSoon(@Req() req: Request, @Query('days') days?: string) {
    return this.proxy.forwardToAnalytics(
      'GET',
      '/analytics/expiring-soon',
      undefined,
      { days },
      this.sso(req),
    );
  }
}
