import { AppError } from '@shared/errors/AppError';
import { IReservationRepository } from '../repositories/IReservationRepository';
import { Reservation } from '../entities/Reservation.entity';

export class GetReservationByIdUseCase {
  constructor(private readonly reservationRepository: IReservationRepository) {}

  async execute(id: string, userId: string): Promise<Reservation> {
    const reservation = await this.reservationRepository.findById(id);

    if (!reservation) {
      throw new AppError('Reservation not found', 404);
    }

    const isOwner = reservation.clientId === userId || reservation.providerId === userId;

    if (!isOwner) {
      throw new AppError('Forbidden', 403);
    }

    return reservation;
  }
}
