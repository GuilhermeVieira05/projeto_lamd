import { AppError } from '@shared/errors/AppError';
import { IServiceRepository } from '../repositories/IServiceRepository';
import { UpdateServiceDTO } from '../dtos/UpdateServiceDTO';
import { ServiceType } from '../entities/ServiceType.entity';

export class UpdateServiceUseCase {
  constructor(private readonly serviceRepository: IServiceRepository) {}

  async execute(id: string, providerId: string, data: UpdateServiceDTO): Promise<ServiceType> {
    const service = await this.serviceRepository.findById(id);

    if (!service) {
      throw new AppError('Service not found', 404);
    }

    if (service.providerId !== providerId) {
      throw new AppError('Forbidden', 403);
    }

    return this.serviceRepository.update(service, data);
  }
}
