import amqp, { Channel, ChannelModel } from 'amqplib';

const RABBITMQ_URL = process.env.RABBITMQ_URL ?? 'amqp://admin:admin@localhost:5672';

const EXCHANGE_NAME = 'reservations';
const EXCHANGE_TYPE = 'topic';

export const QUEUE_NOTIFICATION_PERSIST = 'notification.persist';
export const QUEUE_RESERVATION_COMMANDS = 'reservation.commands';

let connection: ChannelModel | null = null;
let sharedChannel: Channel | null = null;

function scheduleReconnect(): void {
  setTimeout(async () => {
    try {
      console.info('[RabbitMQ] Attempting to reconnect...');
      await getRabbitMQChannel();
      console.info('[RabbitMQ] Reconnected successfully.');
    } catch (err) {
      console.error('[RabbitMQ] Reconnection failed:', err);
    }
  }, 5000);
}

async function ensureConnection(): Promise<ChannelModel> {
  if (connection) return connection;

  const conn = await amqp.connect(RABBITMQ_URL);

  conn.on('error', (err: Error) => {
    console.error('[RabbitMQ] Connection error:', err.message);
    connection = null;
    sharedChannel = null;
    scheduleReconnect();
  });

  conn.on('close', () => {
    console.warn('[RabbitMQ] Connection closed. Reconnecting...');
    connection = null;
    sharedChannel = null;
    scheduleReconnect();
  });

  connection = conn;
  return connection;
}

export async function getRabbitMQChannel(): Promise<Channel> {
  if (sharedChannel) return sharedChannel;

  const conn = await ensureConnection();
  const ch = await conn.createChannel();

  await ch.assertExchange(EXCHANGE_NAME, EXCHANGE_TYPE, { durable: true });

  await ch.assertQueue(QUEUE_NOTIFICATION_PERSIST, { durable: true });
  await ch.bindQueue(QUEUE_NOTIFICATION_PERSIST, EXCHANGE_NAME, 'reservation.*');
  await ch.bindQueue(QUEUE_NOTIFICATION_PERSIST, EXCHANGE_NAME, 'service.*');

  sharedChannel = ch;
  console.info('[RabbitMQ] Shared channel ready. Exchange and queues configured.');
  return sharedChannel;
}

export async function getCommandChannel(): Promise<Channel> {
  const conn = await ensureConnection();
  const ch = await conn.createChannel();

  await ch.assertQueue(QUEUE_RESERVATION_COMMANDS, { durable: true });
  await ch.prefetch(1);

  console.info('[RabbitMQ] Command channel ready (prefetch 1).');
  return ch;
}
