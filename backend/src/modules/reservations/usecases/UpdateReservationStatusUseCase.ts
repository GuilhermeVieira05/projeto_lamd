import { AppError } from '@shared/errors/AppError';
import { ReservationStatus } from '@shared/enums/ReservationStatus';
import { IReservationRepository } from '../repositories/IReservationRepository';
import { UpdateReservationStatusDTO } from '../dtos/UpdateReservationStatusDTO';
import { Reservation } from '../entities/Reservation.entity';

const VALID_TRANSITIONS: Record<ReservationStatus, ReservationStatus[]> = {
  [ReservationStatus.PENDING]: [ReservationStatus.ACCEPTED, ReservationStatus.REFUSED],
  [ReservationStatus.ACCEPTED]: [ReservationStatus.COMPLETED],
  [ReservationStatus.REFUSED]: [],
  [ReservationStatus.COMPLETED]: [],
};

export class UpdateReservationStatusUseCase {
  constructor(private readonly reservationRepository: IReservationRepository) {}

  async execute(
    id: string,
    providerId: string,
    data: UpdateReservationStatusDTO,
  ): Promise<Reservation> {
    const reservation = await this.reservationRepository.findById(id);

    if (!reservation) {
      throw new AppError('Reservation not found', 404);
    }

    if (reservation.providerId !== providerId) {
      throw new AppError('Forbidden', 403);
    }

    const allowed = VALID_TRANSITIONS[reservation.status];

    if (!allowed.includes(data.status)) {
      throw new AppError(
        `Cannot transition from ${reservation.status} to ${data.status}`,
        422,
      );
    }

    reservation.status = data.status;
    return this.reservationRepository.save(reservation);
  }
}
