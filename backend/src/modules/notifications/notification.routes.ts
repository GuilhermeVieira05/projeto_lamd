import { Router } from 'express';
import { authMiddleware } from '@shared/middlewares/authMiddleware';
import { NotificationController } from './notification.controller';

const notificationRoutes = Router();
const notificationController = new NotificationController();

notificationRoutes.get(
  '/',
  authMiddleware,
  (req, res, next) => notificationController.list(req, res, next),
);

// /read-all must come before /:id/read to avoid Express matching "read-all" as an :id
notificationRoutes.patch(
  '/read-all',
  authMiddleware,
  (req, res, next) => notificationController.markAllAsRead(req, res, next),
);

notificationRoutes.patch(
  '/:id/read',
  authMiddleware,
  (req, res, next) => notificationController.markAsRead(req, res, next),
);

export { notificationRoutes };
