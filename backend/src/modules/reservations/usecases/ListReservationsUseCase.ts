import { Role } from '@shared/enums/Role';
import { IReservationRepository } from '../repositories/IReservationRepository';
import { Reservation } from '../entities/Reservation.entity';

export class ListReservationsUseCase {
  constructor(private readonly reservationRepository: IReservationRepository) {}

  execute(userId: string, role: Role): Promise<Reservation[]> {
    if (role === Role.CLIENT) {
      return this.reservationRepository.findAllByClientId(userId);
    }
    return this.reservationRepository.findAllByProviderId(userId);
  }
}
