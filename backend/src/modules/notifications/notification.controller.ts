import { NextFunction, Request, Response } from 'express';
import {
  makeListNotificationsUseCase,
  makeMarkAsReadUseCase,
  makeMarkAllAsReadUseCase,
} from '@shared/container';

export class NotificationController {
  async list(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const result = await makeListNotificationsUseCase().execute(req.user!.id);
      res.json(result);
    } catch (err) {
      next(err);
    }
  }

  async markAsRead(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      await makeMarkAsReadUseCase().execute(req.params.id, req.user!.id);
      res.status(204).send();
    } catch (err) {
      next(err);
    }
  }

  async markAllAsRead(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      await makeMarkAllAsReadUseCase().execute(req.user!.id);
      res.status(204).send();
    } catch (err) {
      next(err);
    }
  }
}
