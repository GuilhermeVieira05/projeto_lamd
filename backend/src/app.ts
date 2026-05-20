import 'reflect-metadata';
import express, { NextFunction, Request, Response } from 'express';
import cors from 'cors';
import { ZodError } from 'zod';
import { AppError } from '@shared/errors/AppError';
import { authRoutes } from '@modules/auth/auth.routes';
import { userRoutes } from '@modules/users/user.routes';
import { serviceRoutes } from '@modules/services/service.routes';
import { reservationRoutes } from '@modules/reservations/reservation.routes';
import { notificationRoutes } from '@modules/notifications/notification.routes';

const app = express();

app.use(cors());
app.use(express.json());

app.get('/health', (_req: Request, res: Response) => {
  res.json({ status: 'ok' });
});

app.use('/auth', authRoutes);
app.use('/users', userRoutes);
app.use('/services', serviceRoutes);
app.use('/reservations', reservationRoutes);
app.use('/notifications', notificationRoutes);

app.use((err: Error, _req: Request, res: Response, _next: NextFunction) => {
  if (err instanceof AppError) {
    return res.status(err.statusCode).json({ message: err.message });
  }

  if (err instanceof ZodError) {
    return res.status(400).json({
      message: 'Validation error',
      errors: err.flatten().fieldErrors,
    });
  }

  console.error(err);
  return res.status(500).json({ message: 'Internal server error' });
});

export { app };
