import { NextFunction, Request, Response } from 'express';
import { CreateServiceDTO } from './dtos/CreateServiceDTO';
import { UpdateServiceDTO } from './dtos/UpdateServiceDTO';
import {
  makeCreateServiceUseCase,
  makeGetServiceByIdUseCase,
  makeListServicesUseCase,
  makeUpdateServiceUseCase,
} from '@shared/container';

export class ServiceController {
  async create(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const dto = CreateServiceDTO.parse(req.body);
      const service = await makeCreateServiceUseCase().execute(req.user!.id, dto);
      res.status(201).json(service);
    } catch (err) {
      next(err);
    }
  }

  async list(_req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const services = await makeListServicesUseCase().execute();
      res.json(services);
    } catch (err) {
      next(err);
    }
  }

  async getById(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const service = await makeGetServiceByIdUseCase().execute(req.params.id);
      res.json(service);
    } catch (err) {
      next(err);
    }
  }

  async update(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const dto = UpdateServiceDTO.parse(req.body);
      const service = await makeUpdateServiceUseCase().execute(req.params.id, req.user!.id, dto);
      res.json(service);
    } catch (err) {
      next(err);
    }
  }
}
