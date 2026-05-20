import { getRabbitMQChannel } from './rabbitmq.connection';

const EXCHANGE_NAME = 'reservations';

export interface IEventPublisher {
  publish(routingKey: string, payload: object): Promise<void>;
}

export class RabbitMQProducer implements IEventPublisher {
  async publish(routingKey: string, payload: object): Promise<void> {
    const channel = await getRabbitMQChannel();

    const content = Buffer.from(JSON.stringify(payload));

    channel.publish(EXCHANGE_NAME, routingKey, content, {
      persistent: true,
      contentType: 'application/json',
    });

    console.info(`[RabbitMQ] Published to exchange "${EXCHANGE_NAME}" with key "${routingKey}":`, payload);
  }
}
