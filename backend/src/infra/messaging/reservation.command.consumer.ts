import { getCommandChannel, getRabbitMQChannel, QUEUE_RESERVATION_COMMANDS } from './rabbitmq.connection';
import { IReservationRepository } from '@modules/reservations/repositories/IReservationRepository';
import { IServiceRepository } from '@modules/services/repositories/IServiceRepository';
import { IEventPublisher } from './producer';

interface ReservationCommandPayload {
  clientId: string;
  clientName: string;
  serviceTypeId: string;
  scheduledAt: string;
  notes?: string;
}

export async function startReservationCommandConsumer(
  reservationRepository: IReservationRepository,
  serviceRepository: IServiceRepository,
  eventPublisher: IEventPublisher,
): Promise<void> {
  const channel = await getCommandChannel();

  await channel.consume(QUEUE_RESERVATION_COMMANDS, async (msg) => {
    if (!msg) return;

    try {
      const payload = JSON.parse(msg.content.toString()) as ReservationCommandPayload;
      const { clientId, clientName, serviceTypeId, scheduledAt, notes } = payload;

      const service = await serviceRepository.findById(serviceTypeId);

      if (!service || !service.active) {
        await eventPublisher.publish('reservation.conflict', {
          targetUserId: clientId,
          reason: 'Service not found or unavailable',
        });
        channel.ack(msg);
        return;
      }

      const scheduledDate = new Date(scheduledAt);
      const conflict = await reservationRepository.findConflict(serviceTypeId, scheduledDate);

      if (conflict) {
        await eventPublisher.publish('reservation.conflict', {
          targetUserId: clientId,
          reason: 'Time slot already reserved',
          serviceType: service.name,
          scheduledAt,
        });
        console.info(`[CommandConsumer] Conflict for service ${serviceTypeId} at ${scheduledAt}`);
        channel.ack(msg);
        return;
      }

      const reservation = await reservationRepository.create({
        clientId,
        serviceTypeId: service.id,
        providerId: service.providerId,
        scheduledAt: scheduledDate,
        notes,
      });

      await eventPublisher.publish('reservation.created', {
        targetUserId: service.providerId,
        reservationId: reservation.id,
        clientName,
        serviceType: service.name,
        scheduledAt: reservation.scheduledAt,
      });

      console.info(`[CommandConsumer] Reservation ${reservation.id} created for client ${clientId}`);
      channel.ack(msg);
    } catch (err) {
      console.error('[CommandConsumer] Failed to process command:', err);
      channel.nack(msg, false, true);
    }
  });

  console.info(`[CommandConsumer] Listening on queue "${QUEUE_RESERVATION_COMMANDS}" (prefetch 1).`);
}
