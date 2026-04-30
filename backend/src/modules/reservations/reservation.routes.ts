import { Router } from 'express';
import { authMiddleware } from '@shared/middlewares/authMiddleware';
import { roleMiddleware } from '@shared/middlewares/roleMiddleware';
import { Role } from '@shared/enums/Role';
import { ReservationController } from './reservation.controller';

const reservationRoutes = Router();
const reservationController = new ReservationController();

reservationRoutes.post(
  '/',
  authMiddleware,
  roleMiddleware(Role.CLIENT),
  (req, res, next) => reservationController.create(req, res, next),
);

reservationRoutes.get(
  '/',
  authMiddleware,
  (req, res, next) => reservationController.list(req, res, next),
);

reservationRoutes.get(
  '/:id',
  authMiddleware,
  (req, res, next) => reservationController.getById(req, res, next),
);

reservationRoutes.patch(
  '/:id/status',
  authMiddleware,
  roleMiddleware(Role.PROVIDER),
  (req, res, next) => reservationController.updateStatus(req, res, next),
);

export { reservationRoutes };
