import { IServiceRepository } from '../repositories/IServiceRepository';
import { CreateServiceDTO } from '../dtos/CreateServiceDTO';
import { ServiceType } from '../entities/ServiceType.entity';

export class CreateServiceUseCase {
  constructor(private readonly serviceRepository: IServiceRepository) {}

  execute(providerId: string, data: CreateServiceDTO): Promise<ServiceType> {
    return this.serviceRepository.create({ ...data, providerId });
  }
}
