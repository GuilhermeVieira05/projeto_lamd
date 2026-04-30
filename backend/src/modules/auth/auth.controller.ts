import { NextFunction, Request, Response } from 'express';
import { RegisterDTO } from './dtos/RegisterDTO';
import { LoginDTO } from './dtos/LoginDTO';
import { makeLoginUseCase, makeRegisterUseCase } from '@shared/container';

export class AuthController {
  async register(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const dto = RegisterDTO.parse(req.body);
      const user = await makeRegisterUseCase().execute(dto);
      res.status(201).json(user);
    } catch (err) {
      next(err);
    }
  }

  async login(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const dto = LoginDTO.parse(req.body);
      const result = await makeLoginUseCase().execute(dto);
      res.json(result);
    } catch (err) {
      next(err);
    }
  }
}
