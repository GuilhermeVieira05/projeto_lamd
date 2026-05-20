import { Reservation } from '@modules/reservations/entities/Reservation.entity';
import { ReservationStatus } from '@shared/enums/ReservationStatus';

export interface CreateReservationData {
  clientId: string;
  serviceTypeId: string;
  providerId: string;
  scheduledAt: Date;
  notes?: string;
}

export interface IReservationRepository {
  findById(id: string): Promise<Reservation | null>;
  findAllByClientId(clientId: string): Promise<Reservation[]>;
  findAllByProviderId(providerId: string): Promise<Reservation[]>;
  findConflict(serviceTypeId: string, scheduledAt: Date): Promise<Reservation | null>;
  findByServiceTypeIdAndStatuses(serviceTypeId: string, statuses: ReservationStatus[]): Promise<Reservation[]>;
  create(data: CreateReservationData): Promise<Reservation>;
  save(reservation: Reservation): Promise<Reservation>;
}
