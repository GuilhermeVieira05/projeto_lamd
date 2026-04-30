import { AppDataSource } from '@infra/database';
import { User } from '@modules/users/entities/User.entity';
import { ServiceType } from '@modules/services/entities/ServiceType.entity';
import { Reservation } from '@modules/reservations/entities/Reservation.entity';
import { UserRepository } from '@modules/users/repositories/UserRepository';
import { ServiceRepository } from '@modules/services/repositories/ServiceRepository';
import { ReservationRepository } from '@modules/reservations/repositories/ReservationRepository';
import { RegisterUseCase } from '@modules/auth/usecases/RegisterUseCase';
import { LoginUseCase } from '@modules/auth/usecases/LoginUseCase';
import { CreateServiceUseCase } from '@modules/services/usecases/CreateServiceUseCase';
import { ListServicesUseCase } from '@modules/services/usecases/ListServicesUseCase';
import { GetServiceByIdUseCase } from '@modules/services/usecases/GetServiceByIdUseCase';
import { UpdateServiceUseCase } from '@modules/services/usecases/UpdateServiceUseCase';
import { CreateReservationUseCase } from '@modules/reservations/usecases/CreateReservationUseCase';
import { ListReservationsUseCase } from '@modules/reservations/usecases/ListReservationsUseCase';
import { GetReservationByIdUseCase } from '@modules/reservations/usecases/GetReservationByIdUseCase';
import { UpdateReservationStatusUseCase } from '@modules/reservations/usecases/UpdateReservationStatusUseCase';

// Auth
export function makeRegisterUseCase(): RegisterUseCase {
  return new RegisterUseCase(new UserRepository(AppDataSource.getRepository(User)));
}

export function makeLoginUseCase(): LoginUseCase {
  return new LoginUseCase(new UserRepository(AppDataSource.getRepository(User)));
}

// Services
function makeServiceRepository(): ServiceRepository {
  return new ServiceRepository(AppDataSource.getRepository(ServiceType));
}

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
  return new UpdateServiceUseCase(makeServiceRepository());
}

// Reservations
function makeReservationRepository(): ReservationRepository {
  return new ReservationRepository(AppDataSource.getRepository(Reservation));
}

export function makeCreateReservationUseCase(): CreateReservationUseCase {
  return new CreateReservationUseCase(makeReservationRepository(), makeServiceRepository());
}

export function makeListReservationsUseCase(): ListReservationsUseCase {
  return new ListReservationsUseCase(makeReservationRepository());
}

export function makeGetReservationByIdUseCase(): GetReservationByIdUseCase {
  return new GetReservationByIdUseCase(makeReservationRepository());
}

export function makeUpdateReservationStatusUseCase(): UpdateReservationStatusUseCase {
  return new UpdateReservationStatusUseCase(makeReservationRepository());
}
