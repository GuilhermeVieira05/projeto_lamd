import { Reservation } from '@modules/reservations/entities/Reservation.entity';

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
  create(data: CreateReservationData): Promise<Reservation>;
  save(reservation: Reservation): Promise<Reservation>;
}
