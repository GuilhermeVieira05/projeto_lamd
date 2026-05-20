import 'dotenv/config';
import http from 'http';
import { app } from './app';
import { AppDataSource } from '@infra/database';
import { initWebSocketServer } from '@infra/websocket';
import { startNotificationConsumer, startReservationCommandConsumer } from '@infra/messaging';
import {
  makeNotificationRepository,
  makeReservationRepository,
  makeEventPublisher,
} from '@shared/container';
import { ServiceRepository } from '@modules/services/repositories/ServiceRepository';
import { ServiceType } from '@modules/services/entities/ServiceType.entity';

const PORT = process.env.PORT ?? 3000;

AppDataSource.initialize()
  .then(() => {
    console.info('Database connected');

    const httpServer = http.createServer(app);
    initWebSocketServer(httpServer);

    httpServer.listen(PORT, () => {
      console.info(`Server running on port ${PORT}`);

      const notificationRepo = makeNotificationRepository();
      const reservationRepo = makeReservationRepository();
      const serviceRepo = new ServiceRepository(AppDataSource.getRepository(ServiceType));
      const eventPublisher = makeEventPublisher();

      startNotificationConsumer(notificationRepo).catch((err) =>
        console.error('[RabbitMQ] Failed to start notification consumer:', err),
      );

      startReservationCommandConsumer(reservationRepo, serviceRepo, eventPublisher).catch((err) =>
        console.error('[RabbitMQ] Failed to start command consumer:', err),
      );
    });
  })
  .catch((err) => {
    console.error('Database connection failed:', err);
    process.exit(1);
  });
