import { IServiceRepository } from '../repositories/IServiceRepository';
import { ServiceType } from '../entities/ServiceType.entity';

export class ListMyServicesUseCase {
  constructor(private readonly serviceRepository: IServiceRepository) {}

  execute(providerId: string): Promise<ServiceType[]> {
    return this.serviceRepository.findByProvider(providerId);
  }
}
