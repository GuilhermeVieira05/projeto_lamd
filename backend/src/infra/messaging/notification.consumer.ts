import { getRabbitMQChannel, QUEUE_NOTIFICATION_PERSIST } from './rabbitmq.connection';
import { INotificationRepository } from '@modules/notifications/repositories/INotificationRepository';

interface NotificationPayload {
  targetUserId: string;
  [key: string]: unknown;
}

export async function startNotificationConsumer(
  notificationRepository: INotificationRepository,
): Promise<void> {
  const channel = await getRabbitMQChannel();

  await channel.consume(QUEUE_NOTIFICATION_PERSIST, async (msg) => {
    if (!msg) return;

    const routingKey = msg.fields.routingKey;

    try {
      const payload = JSON.parse(msg.content.toString()) as NotificationPayload;
      const { targetUserId } = payload;

      if (!targetUserId) {
        channel.ack(msg);
        return;
      }

      const notification = await notificationRepository.create({
        userId: targetUserId,
        type: routingKey,
        channel: 'in_app',
        payload,
      });

      console.info(`[NotificationConsumer] Persisted "${routingKey}" for user ${targetUserId}`);

      try {
        const { wsRegistry } = await import('../websocket/ws.registry');
        wsRegistry.send(targetUserId, 'notification.new', notification);
      } catch {
        console.warn('[NotificationConsumer] WebSocket registry unavailable — notification persisted only.');
      }

      channel.ack(msg);
    } catch (err) {
      console.error(`[NotificationConsumer] Failed to process "${routingKey}":`, err);
      channel.nack(msg, false, false);
    }
  });

  console.info(`[NotificationConsumer] Listening on queue "${QUEUE_NOTIFICATION_PERSIST}".`);
}
