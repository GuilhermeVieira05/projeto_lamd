import { AppError } from '@shared/errors/AppError';
import { IServiceRepository } from '../repositories/IServiceRepository';
import { ServiceType } from '../entities/ServiceType.entity';

export class GetServiceByIdUseCase {
  constructor(private readonly serviceRepository: IServiceRepository) {}

  async execute(id: string): Promise<ServiceType> {
    const service = await this.serviceRepository.findById(id);

    if (!service) {
      throw new AppError('Service not found', 404);
    }

    return service;
  }
}
