import { AppError } from '@shared/errors/AppError';
import { ReservationStatus } from '@shared/enums/ReservationStatus';
import { IServiceRepository } from '../repositories/IServiceRepository';
import { IReservationRepository } from '@modules/reservations/repositories/IReservationRepository';
import { IEventPublisher } from '@infra/messaging';
import { UpdateServiceDTO } from '../dtos/UpdateServiceDTO';
import { ServiceType } from '../entities/ServiceType.entity';

export class UpdateServiceUseCase {
  constructor(
    private readonly serviceRepository: IServiceRepository,
    private readonly reservationRepository: IReservationRepository,
    private readonly eventPublisher: IEventPublisher,
  ) {}

  async execute(id: string, providerId: string, data: UpdateServiceDTO): Promise<ServiceType> {
    const service = await this.serviceRepository.findById(id);

    if (!service) {
      throw new AppError('Service not found', 404);
    }

    if (service.providerId !== providerId) {
      throw new AppError('Forbidden', 403);
    }

    const isDeactivating = data.active === false && service.active === true;
    const isPriceOrDurationChange =
      (data.price !== undefined && Number(data.price) !== Number(service.price)) ||
      (data.durationMinutes !== undefined && data.durationMinutes !== service.durationMinutes);

    const updated = await this.serviceRepository.update(service, data);

    if (isDeactivating) {
      const affected = await this.reservationRepository.findByServiceTypeIdAndStatuses(id, [
        ReservationStatus.PENDING,
        ReservationStatus.ACCEPTED,
      ]);

      for (const reservation of affected) {
        reservation.status = ReservationStatus.CANCELLED;
        await this.reservationRepository.save(reservation);

        await this.eventPublisher.publish('service.deactivated', {
          targetUserId: reservation.clientId,
          serviceId: id,
          serviceType: service.name,
          reservationId: reservation.id,
        });
      }

      console.info(`[UpdateServiceUseCase] Service ${id} deactivated — ${affected.length} reservation(s) cancelled.`);
    } else if (isPriceOrDurationChange) {
      const affected = await this.reservationRepository.findByServiceTypeIdAndStatuses(id, [
        ReservationStatus.PENDING,
        ReservationStatus.ACCEPTED,
      ]);

      for (const reservation of affected) {
        await this.eventPublisher.publish('service.updated', {
          targetUserId: reservation.clientId,
          serviceId: id,
          serviceType: service.name,
          reservationId: reservation.id,
        });
      }

      console.info(`[UpdateServiceUseCase] Service ${id} updated — ${affected.length} client(s) notified.`);
    }

    return updated;
  }
}
