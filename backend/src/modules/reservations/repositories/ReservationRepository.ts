import { In, Repository } from 'typeorm';
import { Reservation } from '@modules/reservations/entities/Reservation.entity';
import { CreateReservationData, IReservationRepository } from './IReservationRepository';
import { ReservationStatus } from '@shared/enums/ReservationStatus';

const RELATIONS = ['client', 'provider', 'serviceType'];

export class ReservationRepository implements IReservationRepository {
  constructor(private readonly repository: Repository<Reservation>) {}

  findById(id: string): Promise<Reservation | null> {
    return this.repository.findOne({ where: { id }, relations: RELATIONS });
  }

  findAllByClientId(clientId: string): Promise<Reservation[]> {
    return this.repository.find({
      where: { clientId },
      relations: RELATIONS,
      order: { createdAt: 'DESC' },
    });
  }

  findAllByProviderId(providerId: string): Promise<Reservation[]> {
    return this.repository.find({
      where: { providerId },
      relations: RELATIONS,
      order: { createdAt: 'DESC' },
    });
  }

  findConflict(serviceTypeId: string, scheduledAt: Date): Promise<Reservation | null> {
    return this.repository.findOne({
      where: {
        serviceTypeId,
        scheduledAt,
        status: In([ReservationStatus.PENDING, ReservationStatus.ACCEPTED]),
      },
    });
  }

  findByServiceTypeIdAndStatuses(serviceTypeId: string, statuses: ReservationStatus[]): Promise<Reservation[]> {
    return this.repository.find({
      where: { serviceTypeId, status: In(statuses) },
      relations: RELATIONS,
    });
  }

  async create(data: CreateReservationData): Promise<Reservation> {
    const reservation = this.repository.create(data);
    return this.repository.save(reservation);
  }

  save(reservation: Reservation): Promise<Reservation> {
    return this.repository.save(reservation);
  }
}
