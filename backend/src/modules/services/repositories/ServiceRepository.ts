import { Repository } from 'typeorm';
import { ServiceType } from '@modules/services/entities/ServiceType.entity';
import {
  CreateServiceData,
  IServiceRepository,
  UpdateServiceData,
} from './IServiceRepository';

export class ServiceRepository implements IServiceRepository {
  constructor(private readonly repository: Repository<ServiceType>) {}

  findById(id: string): Promise<ServiceType | null> {
    return this.repository.findOne({ where: { id }, relations: ['provider'] });
  }

  findAllActive(): Promise<ServiceType[]> {
    return this.repository.find({
      where: { active: true },
      relations: ['provider'],
      order: { createdAt: 'DESC' },
    });
  }

  async create(data: CreateServiceData): Promise<ServiceType> {
    const service = this.repository.create(data);
    return this.repository.save(service);
  }

  async update(service: ServiceType, data: UpdateServiceData): Promise<ServiceType> {
    Object.assign(service, data);
    return this.repository.save(service);
  }
}
