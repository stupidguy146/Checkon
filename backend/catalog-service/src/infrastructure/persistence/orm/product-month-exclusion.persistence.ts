import { Column, Entity, Index, PrimaryGeneratedColumn } from 'typeorm';

@Entity('product_month_exclusions')
@Index(['ssoId', 'productId', 'month'], { unique: true })
export class ProductMonthExclusionRecord {
  @PrimaryGeneratedColumn()
  id: number;

  @Column({ type: 'uuid' })
  ssoId: string;

  @Column({ type: 'uuid' })
  productId: string;

  @Column({ type: 'varchar', length: 7 })
  month: string;
}
