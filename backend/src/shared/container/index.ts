import { AppDataSource } from '@infra/database';
import { RabbitMQProducer } from '@infra/messaging';
import { User } from '@modules/users/entities/User.entity';
import { ServiceType } from '@modules/services/entities/ServiceType.entity';
import { Reservation } from '@modules/reservations/entities/Reservation.entity';
import { Notification } from '@modules/notifications/entities/notification.entity';
import { UserRepository } from '@modules/users/repositories/UserRepository';
import { ServiceRepository } from '@modules/services/repositories/ServiceRepository';
import { ReservationRepository } from '@modules/reservations/repositories/ReservationRepository';
import { NotificationRepository } from '@modules/notifications/repositories/NotificationRepository';
import { RegisterUseCase } from '@modules/auth/usecases/RegisterUseCase';
import { LoginUseCase } from '@modules/auth/usecases/LoginUseCase';
import { GetUserByIdUseCase } from '@modules/users/usecases/GetUserByIdUseCase';
import { GetMeUseCase } from '@modules/users/usecases/GetMeUseCase';
import { UpdateMeUseCase } from '@modules/users/usecases/UpdateMeUseCase';
import { DeleteMeUseCase } from '@modules/users/usecases/DeleteMeUseCase';
import { CreateServiceUseCase } from '@modules/services/usecases/CreateServiceUseCase';
import { ListServicesUseCase } from '@modules/services/usecases/ListServicesUseCase';
import { GetServiceByIdUseCase } from '@modules/services/usecases/GetServiceByIdUseCase';
import { UpdateServiceUseCase } from '@modules/services/usecases/UpdateServiceUseCase';
import { CreateReservationUseCase } from '@modules/reservations/usecases/CreateReservationUseCase';
import { ListReservationsUseCase } from '@modules/reservations/usecases/ListReservationsUseCase';
import { GetReservationByIdUseCase } from '@modules/reservations/usecases/GetReservationByIdUseCase';
import { UpdateReservationStatusUseCase } from '@modules/reservations/usecases/UpdateReservationStatusUseCase';
import { CancelReservationUseCase } from '@modules/reservations/usecases/CancelReservationUseCase';
import { ListNotificationsUseCase } from '@modules/notifications/usecases/ListNotificationsUseCase';
import { MarkAsReadUseCase } from '@modules/notifications/usecases/MarkAsReadUseCase';
import { MarkAllAsReadUseCase } from '@modules/notifications/usecases/MarkAllAsReadUseCase';

function makeUserRepository(): UserRepository {
  return new UserRepository(AppDataSource.getRepository(User));
}

function makeServiceRepository(): ServiceRepository {
  return new ServiceRepository(AppDataSource.getRepository(ServiceType));
}

export function makeReservationRepository(): ReservationRepository {
  return new ReservationRepository(AppDataSource.getRepository(Reservation));
}

export function makeNotificationRepository(): NotificationRepository {
  return new NotificationRepository(AppDataSource.getRepository(Notification));
}

export function makeEventPublisher(): RabbitMQProducer {
  return new RabbitMQProducer();
}

// Auth
export function makeRegisterUseCase(): RegisterUseCase {
  return new RegisterUseCase(makeUserRepository());
}

export function makeLoginUseCase(): LoginUseCase {
  return new LoginUseCase(makeUserRepository());
}

// Users
export function makeGetUserByIdUseCase(): GetUserByIdUseCase {
  return new GetUserByIdUseCase(makeUserRepository());
}

export function makeGetMeUseCase(): GetMeUseCase {
  return new GetMeUseCase(makeUserRepository());
}

export function makeUpdateMeUseCase(): UpdateMeUseCase {
  return new UpdateMeUseCase(makeUserRepository());
}

export function makeDeleteMeUseCase(): DeleteMeUseCase {
  return new DeleteMeUseCase(makeUserRepository());
}

// Services
export function makeCreateServiceUseCase(): CreateServiceUseCase {
  return new CreateServiceUseCase(makeServiceRepository());
}

export function makeListServicesUseCase(): ListServicesUseCase {
  return new ListServicesUseCase(makeServiceRepository());
}

export function makeGetServiceByIdUseCase(): GetServiceByIdUseCase {
  return new GetServiceByIdUseCase(makeServiceRepository());
}

export function makeUpdateServiceUseCase(): UpdateServiceUseCase {
  return new UpdateServiceUseCase(makeServiceRepository(), makeReservationRepository(), makeEventPublisher());
}

// Reservations
export function makeCreateReservationUseCase(): CreateReservationUseCase {
  return new CreateReservationUseCase(makeServiceRepository());
}

export function makeListReservationsUseCase(): ListReservationsUseCase {
  return new ListReservationsUseCase(makeReservationRepository());
}

export function makeGetReservationByIdUseCase(): GetReservationByIdUseCase {
  return new GetReservationByIdUseCase(makeReservationRepository());
}

export function makeUpdateReservationStatusUseCase(): UpdateReservationStatusUseCase {
  return new UpdateReservationStatusUseCase(makeReservationRepository(), makeEventPublisher());
}

export function makeCancelReservationUseCase(): CancelReservationUseCase {
  return new CancelReservationUseCase(makeReservationRepository(), makeEventPublisher());
}

// Notifications
export function makeListNotificationsUseCase(): ListNotificationsUseCase {
  return new ListNotificationsUseCase(makeNotificationRepository());
}

export function makeMarkAsReadUseCase(): MarkAsReadUseCase {
  return new MarkAsReadUseCase(makeNotificationRepository());
}

export function makeMarkAllAsReadUseCase(): MarkAllAsReadUseCase {
  return new MarkAllAsReadUseCase(makeNotificationRepository());
}
