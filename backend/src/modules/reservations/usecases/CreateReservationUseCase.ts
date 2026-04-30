import { AppError } from '@shared/errors/AppError';
import { IReservationRepository } from '../repositories/IReservationRepository';
import { IServiceRepository } from '@modules/services/repositories/IServiceRepository';
import { CreateReservationDTO } from '../dtos/CreateReservationDTO';
import { Reservation } from '../entities/Reservation.entity';

export class CreateReservationUseCase {
  constructor(
    private readonly reservationRepository: IReservationRepository,
    private readonly serviceRepository: IServiceRepository,
  ) {}

  async execute(clientId: string, data: CreateReservationDTO): Promise<Reservation> {
    const service = await this.serviceRepository.findById(data.serviceTypeId);

    if (!service || !service.active) {
      throw new AppError('Service not found or unavailable', 404);
    }

    const scheduledAt = new Date(data.scheduledAt);

    if (scheduledAt <= new Date()) {
      throw new AppError('Scheduled date must be in the future', 400);
    }

    return this.reservationRepository.create({
      clientId,
      serviceTypeId: service.id,
      providerId: service.providerId,
      scheduledAt,
      notes: data.notes,
    });
  }
}
