import { NextFunction, Request, Response } from 'express';
import { AppError } from '@shared/errors/AppError';
import { Role } from '@shared/enums/Role';

export function roleMiddleware(...roles: Role[]) {
  return (req: Request, _res: Response, next: NextFunction): void => {
    if (!req.user) {
      return next(new AppError('Not authenticated', 401));
    }

    if (!roles.includes(req.user.role as Role)) {
      return next(new AppError('Insufficient permissions', 403));
    }

    next();
  };
}
