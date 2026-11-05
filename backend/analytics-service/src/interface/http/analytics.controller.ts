import {
  BadRequestException,
  Controller,
  Get,
  Headers,
  Query,
} from '@nestjs/common';
import { AnalyticsUseCases } from '../../application/use-case/analytics.use-cases';
import { DomainError, AnalyticsErrorCode } from '../../shared/errors';
import { SSO_ID_HEADER } from '../../shared/constants';

function requireSsoId(ssoId?: string): string {
  if (!ssoId) {
    throw new DomainError(AnalyticsErrorCode.MISSING_SSO_ID);
  }
  return ssoId;
}

/**
 * Inbound adapter: analytics HTTP controller (prefix 'analytics').
 *   GET /analytics/summary        — grand total + spend by month/category
 *   GET /analytics/expiring-soon  — items expiring within N days
 */
@Controller()
export class AnalyticsController {
  constructor(private readonly analytics: AnalyticsUseCases) {}

  @Get('summary')
  summary(@Headers(SSO_ID_HEADER) ssoId: string) {
    return this.analytics.summary(requireSsoId(ssoId));
  }

  @Get('summary-month')
  summaryByMonth(
    @Headers(SSO_ID_HEADER) ssoId: string,
    @Query('month') month?: string,
  ) {
    const m =
      month && /^\d{4}-\d{2}$/.test(month)
        ? month
        : new Date().toISOString().slice(0, 7);
    return this.analytics.summaryByMonth(requireSsoId(ssoId), m);
  }

  @Get('spend-by-month')
  spendByMonth(
    @Headers(SSO_ID_HEADER) ssoId: string,
    @Query('months') months?: string,
    @Query('month') month?: string,
  ) {
    const n = months ? parseInt(months, 10) : 6;
    if (month && !/^\d{4}-(0[1-9]|1[0-2])$/.test(month)) {
      throw new BadRequestException('month must be in YYYY-MM format');
    }
    return this.analytics.spendByMonth(
      requireSsoId(ssoId),
      Number.isNaN(n) ? 6 : n,
      month,
    );
  }

  @Get('expiring-soon')
  expiringSoon(
    @Headers(SSO_ID_HEADER) ssoId: string,
    @Query('days') days?: string,
  ) {
    const n = days ? parseInt(days, 10) : 7;
    return this.analytics.expiringSoon(
      Number.isNaN(n) ? 7 : n,
      requireSsoId(ssoId),
    );
  }
}
