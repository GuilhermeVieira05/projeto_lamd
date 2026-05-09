import {
  Column,
  CreateDateColumn,
  Entity,
  OneToMany,
  PrimaryGeneratedColumn,
} from 'typeorm';
import { Role } from '@shared/enums/Role';
import { ServiceType } from '@modules/services/entities/ServiceType.entity';
import { Reservation } from '@modules/reservations/entities/Reservation.entity';

@Entity('users')
export class User {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ type: 'varchar', length: 100 })
  name: string;

  @Column({ type: 'varchar', length: 150, unique: true })
  email: string;

  @Column({ name: 'password_hash', type: 'varchar', select: false })
  passwordHash: string;

  @Column({ type: 'enum', enum: Role })
  role: Role;

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;

  @OneToMany(() => ServiceType, (service) => service.provider)
  services: ServiceType[];

  @OneToMany(() => Reservation, (reservation) => reservation.client)
  reservationsAsClient: Reservation[];

  @OneToMany(() => Reservation, (reservation) => reservation.provider)
  reservationsAsProvider: Reservation[];
}
