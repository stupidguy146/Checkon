import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Between, Repository } from 'typeorm';
import { PurchaseRepositoryPort } from '../../domain/port/purchase.repository.port';
import { Purchase } from '../../domain/model/purchase';
import { PurchaseRecord } from './orm/purchase.persistence';
import { PurchaseMapper } from './mapper/purchase.mapper';

@Injectable()
export class PurchaseRepositoryAdapter implements PurchaseRepositoryPort {
  constructor(
    @InjectRepository(PurchaseRecord)
    private readonly purchases: Repository<PurchaseRecord>,
  ) {}

  async create(purchase: Purchase): Promise<Purchase> {
    const saved = await this.purchases.save(PurchaseMapper.toRecord(purchase));
    return PurchaseMapper.toDomain(saved);
  }

  async findByProduct(productId: string, ssoId: string): Promise<Purchase[]> {
    const rows = await this.purchases.find({
      where: { productId, ssoId },
      order: { createdAt: 'DESC' },
    });
    return rows.map((r) => PurchaseMapper.toDomain(r));
  }

  async findByMonth(ssoId: string, month: string): Promise<Purchase[]> {
    // month = yyyy-mm → [first, last] of that month (inclusive)
    const [y, m] = month.split('-').map((v) => parseInt(v, 10));
    const first = `${month}-01`;
    const lastDay = new Date(y, m, 0).getDate(); // day 0 of next month
    const last = `${month}-${String(lastDay).padStart(2, '0')}`;
    const rows = await this.purchases.find({
      where: { ssoId, purchasedAt: Between(first, last) },
      order: { purchasedAt: 'DESC' },
    });
    return rows.map((r) => PurchaseMapper.toDomain(r));
  }

  async findAllByOwner(ssoId: string): Promise<Purchase[]> {
    const rows = await this.purchases.find({
      where: { ssoId },
      order: { purchasedAt: 'ASC' },
    });
    return rows.map((r) => PurchaseMapper.toDomain(r));
  }
}
