import { ServiceType } from '@modules/services/entities/ServiceType.entity';

export interface CreateServiceData {
  name: string;
  description: string;
  providerId: string;
  price: number;
  durationMinutes: number;
}

export interface UpdateServiceData {
  name?: string;
  description?: string;
  price?: number;
  durationMinutes?: number;
  active?: boolean;
}

export interface IServiceRepository {
  findById(id: string): Promise<ServiceType | null>;
  findAllActive(): Promise<ServiceType[]>;
  create(data: CreateServiceData): Promise<ServiceType>;
  update(service: ServiceType, data: UpdateServiceData): Promise<ServiceType>;
}
