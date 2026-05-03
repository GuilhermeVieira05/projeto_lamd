import { NextFunction, Request, Response } from 'express';
import { UpdateUserDTO } from './dtos/UpdateUserDTO';
import {
  makeDeleteMeUseCase,
  makeGetMeUseCase,
  makeGetUserByIdUseCase,
  makeUpdateMeUseCase,
} from '@shared/container';

export class UserController {
  async getMe(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const user = await makeGetMeUseCase().execute(req.user!.id);
      res.json(user);
    } catch (err) {
      next(err);
    }
  }

  async getById(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const user = await makeGetUserByIdUseCase().execute(req.params.id);
      res.json(user);
    } catch (err) {
      next(err);
    }
  }

  async updateMe(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const dto = UpdateUserDTO.parse(req.body);
      const user = await makeUpdateMeUseCase().execute(req.user!.id, dto);
      res.json(user);
    } catch (err) {
      next(err);
    }
  }

  async deleteMe(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      await makeDeleteMeUseCase().execute(req.user!.id);
      res.status(204).send();
    } catch (err) {
      next(err);
    }
  }
}
