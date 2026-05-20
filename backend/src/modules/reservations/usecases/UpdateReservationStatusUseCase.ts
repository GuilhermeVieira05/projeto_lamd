import { AppError } from '@shared/errors/AppError';
import { ReservationStatus } from '@shared/enums/ReservationStatus';
import { IReservationRepository } from '../repositories/IReservationRepository';
import { IEventPublisher } from '@infra/messaging';
import { UpdateReservationStatusDTO } from '../dtos/UpdateReservationStatusDTO';
import { Reservation } from '../entities/Reservation.entity';

const VALID_TRANSITIONS: Record<ReservationStatus, ReservationStatus[]> = {
  [ReservationStatus.PENDING]: [ReservationStatus.ACCEPTED, ReservationStatus.REFUSED],
  [ReservationStatus.ACCEPTED]: [ReservationStatus.COMPLETED],
  [ReservationStatus.REFUSED]: [],
  [ReservationStatus.COMPLETED]: [],
  [ReservationStatus.CANCELLED]: [],
};

const STATUS_ROUTING_KEY: Partial<Record<ReservationStatus, string>> = {
  [ReservationStatus.ACCEPTED]: 'reservation.accepted',
  [ReservationStatus.REFUSED]: 'reservation.refused',
  [ReservationStatus.COMPLETED]: 'reservation.completed',
};

export class UpdateReservationStatusUseCase {
  constructor(
    private readonly reservationRepository: IReservationRepository,
    private readonly eventPublisher: IEventPublisher,
  ) {}

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
    const updated = await this.reservationRepository.save(reservation);

    const routingKey = STATUS_ROUTING_KEY[data.status];
    if (routingKey) {
      await this.eventPublisher.publish(routingKey, {
        targetUserId: reservation.clientId,
        reservationId: reservation.id,
        providerName: reservation.provider?.name ?? providerId,
        scheduledAt: reservation.scheduledAt,
        completedAt: data.status === ReservationStatus.COMPLETED ? updated.updatedAt : undefined,
      });
    }

    return updated;
  }
}
