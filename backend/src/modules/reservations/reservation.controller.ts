import { NextFunction, Request, Response } from 'express';
import { Role } from '@shared/enums/Role';
import { CreateReservationDTO } from './dtos/CreateReservationDTO';
import { UpdateReservationStatusDTO } from './dtos/UpdateReservationStatusDTO';
import {
  makeCreateReservationUseCase,
  makeGetReservationByIdUseCase,
  makeListReservationsUseCase,
  makeUpdateReservationStatusUseCase,
  makeCancelReservationUseCase,
} from '@shared/container';

export class ReservationController {
  async create(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const dto = CreateReservationDTO.parse(req.body);
      await makeCreateReservationUseCase().execute(req.user!.id, req.user!.name, dto);
      res.status(202).json({ message: 'Reservation request received. You will be notified shortly.' });
    } catch (err) {
      next(err);
    }
  }

  async list(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const reservations = await makeListReservationsUseCase().execute(
        req.user!.id,
        req.user!.role as Role,
      );
      res.json(reservations);
    } catch (err) {
      next(err);
    }
  }

  async getById(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const reservation = await makeGetReservationByIdUseCase().execute(
        req.params.id,
        req.user!.id,
      );
      res.json(reservation);
    } catch (err) {
      next(err);
    }
  }

  async updateStatus(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const dto = UpdateReservationStatusDTO.parse(req.body);
      const reservation = await makeUpdateReservationStatusUseCase().execute(
        req.params.id,
        req.user!.id,
        dto,
      );
      res.json(reservation);
    } catch (err) {
      next(err);
    }
  }

  async cancel(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const reservation = await makeCancelReservationUseCase().execute(
        req.params.id,
        req.user!.id,
        req.user!.role as 'CLIENT' | 'PROVIDER',
      );
      res.json(reservation);
    } catch (err) {
      next(err);
    }
  }
}
