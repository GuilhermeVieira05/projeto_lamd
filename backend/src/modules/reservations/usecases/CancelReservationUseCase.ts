import { AppError } from '@shared/errors/AppError';
import { ReservationStatus } from '@shared/enums/ReservationStatus';
import { IReservationRepository } from '../repositories/IReservationRepository';
import { IEventPublisher } from '@infra/messaging';
import { Reservation } from '../entities/Reservation.entity';

export class CancelReservationUseCase {
  constructor(
    private readonly reservationRepository: IReservationRepository,
    private readonly eventPublisher: IEventPublisher,
  ) {}

  async execute(id: string, requesterId: string, requesterRole: 'CLIENT' | 'PROVIDER'): Promise<Reservation> {
    const reservation = await this.reservationRepository.findById(id);

    if (!reservation) {
      throw new AppError('Reservation not found', 404);
    }

    if (requesterRole === 'CLIENT') {
      if (reservation.clientId !== requesterId) {
        throw new AppError('Forbidden', 403);
      }
      if (reservation.status !== ReservationStatus.PENDING) {
        throw new AppError(`Cannot cancel a reservation with status ${reservation.status}`, 422);
      }

      reservation.status = ReservationStatus.CANCELLED;
      const saved = await this.reservationRepository.save(reservation);

      await this.eventPublisher.publish('reservation.cancelled', {
        targetUserId: reservation.providerId,
        reservationId: reservation.id,
        clientName: reservation.client?.name ?? requesterId,
        serviceType: reservation.serviceType?.name ?? reservation.serviceTypeId,
      });

      return saved;
    }

    if (reservation.providerId !== requesterId) {
      throw new AppError('Forbidden', 403);
    }
    if (reservation.status !== ReservationStatus.ACCEPTED) {
      throw new AppError(`Provider can only cancel ACCEPTED reservations, current status: ${reservation.status}`, 422);
    }

    reservation.status = ReservationStatus.CANCELLED;
    const saved = await this.reservationRepository.save(reservation);

    await this.eventPublisher.publish('reservation.cancelled_by_provider', {
      targetUserId: reservation.clientId,
      reservationId: reservation.id,
      providerName: reservation.provider?.name ?? requesterId,
      serviceType: reservation.serviceType?.name ?? reservation.serviceTypeId,
    });

    return saved;
  }
}
