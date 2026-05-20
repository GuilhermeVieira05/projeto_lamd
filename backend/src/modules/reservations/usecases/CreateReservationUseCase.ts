import { AppError } from '@shared/errors/AppError';
import { IServiceRepository } from '@modules/services/repositories/IServiceRepository';
import { getRabbitMQChannel, QUEUE_RESERVATION_COMMANDS } from '@infra/messaging/rabbitmq.connection';
import { CreateReservationDTO } from '../dtos/CreateReservationDTO';

export class CreateReservationUseCase {
  constructor(private readonly serviceRepository: IServiceRepository) {}

  async execute(clientId: string, clientName: string, data: CreateReservationDTO): Promise<void> {
    const service = await this.serviceRepository.findById(data.serviceTypeId);

    if (!service || !service.active) {
      throw new AppError('Service not found or unavailable', 404);
    }

    const scheduledAt = new Date(data.scheduledAt);

    if (scheduledAt <= new Date()) {
      throw new AppError('Scheduled date must be in the future', 400);
    }

    const channel = await getRabbitMQChannel();
    channel.sendToQueue(
      QUEUE_RESERVATION_COMMANDS,
      Buffer.from(JSON.stringify({
        clientId,
        clientName,
        serviceTypeId: data.serviceTypeId,
        scheduledAt: scheduledAt.toISOString(),
        notes: data.notes,
      })),
      { persistent: true, contentType: 'application/json' },
    );

    console.info(`[CreateReservationUseCase] Command queued for client ${clientId}`);
  }
}
