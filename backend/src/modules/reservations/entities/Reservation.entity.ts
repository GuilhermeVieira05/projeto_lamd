import {
  Column,
  CreateDateColumn,
  Entity,
  JoinColumn,
  ManyToOne,
  PrimaryGeneratedColumn,
  UpdateDateColumn,
} from 'typeorm';
import { ReservationStatus } from '@shared/enums/ReservationStatus';
import { User } from '@modules/users/entities/User.entity';
import { ServiceType } from '@modules/services/entities/ServiceType.entity';

@Entity('reservations')
export class Reservation {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'client_id', type: 'uuid' })
  clientId: string;

  @Column({ name: 'service_type_id', type: 'uuid' })
  serviceTypeId: string;

  @Column({ name: 'provider_id', type: 'uuid' })
  providerId: string;

  @Column({ type: 'enum', enum: ReservationStatus, default: ReservationStatus.PENDING })
  status: ReservationStatus;

  @Column({ name: 'scheduled_at', type: 'timestamptz' })
  scheduledAt: Date;

  @Column({ type: 'text', nullable: true })
  notes: string | null;

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at' })
  updatedAt: Date;

  @ManyToOne(() => User, (user) => user.reservationsAsClient)
  @JoinColumn({ name: 'client_id' })
  client: User;

  @ManyToOne(() => User, (user) => user.reservationsAsProvider)
  @JoinColumn({ name: 'provider_id' })
  provider: User;

  @ManyToOne(() => ServiceType, (service) => service.reservations)
  @JoinColumn({ name: 'service_type_id' })
  serviceType: ServiceType;
}
