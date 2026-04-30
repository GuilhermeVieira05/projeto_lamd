import { NextFunction, Request, Response } from 'express';
import jwt from 'jsonwebtoken';
import { AppError } from '@shared/errors/AppError';

interface TokenPayload {
  sub: string;
  name: string;
  role: string;
}

export function authMiddleware(req: Request, _res: Response, next: NextFunction): void {
  const authHeader = req.headers.authorization;

  if (!authHeader?.startsWith('Bearer ')) {
    return next(new AppError('Token not provided', 401));
  }

  const token = authHeader.split(' ')[1];

  try {
    const { sub, name, role } = jwt.verify(
      token,
      process.env.JWT_SECRET ?? '',
    ) as TokenPayload;

    req.user = { id: sub, name, role };
    next();
  } catch {
    next(new AppError('Invalid token', 401));
  }
}
