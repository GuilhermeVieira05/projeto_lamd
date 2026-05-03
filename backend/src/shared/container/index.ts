import { AppDataSource } from '@infra/database';
import { User } from '@modules/users/entities/User.entity';
import { ServiceType } from '@modules/services/entities/ServiceType.entity';
import { Reservation } from '@modules/reservations/entities/Reservation.entity';
import { UserRepository } from '@modules/users/repositories/UserRepository';
import { ServiceRepository } from '@modules/services/repositories/ServiceRepository';
import { ReservationRepository } from '@modules/reservations/repositories/ReservationRepository';
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

// Users
function makeUserRepository(): UserRepository {
  return new UserRepository(AppDataSource.getRepository(User));
}

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

// Auth
export function makeRegisterUseCase(): RegisterUseCase {
  return new RegisterUseCase(makeUserRepository());
}

export function makeLoginUseCase(): LoginUseCase {
  return new LoginUseCase(makeUserRepository());
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
