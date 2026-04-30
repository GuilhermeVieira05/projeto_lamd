import { IServiceRepository } from '../repositories/IServiceRepository';
import { ServiceType } from '../entities/ServiceType.entity';

export class ListServicesUseCase {
  constructor(private readonly serviceRepository: IServiceRepository) {}

  execute(): Promise<ServiceType[]> {
    return this.serviceRepository.findAllActive();
  }
}
