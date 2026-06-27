import { Router } from 'express';
import { authMiddleware } from '@shared/middlewares/authMiddleware';
import { roleMiddleware } from '@shared/middlewares/roleMiddleware';
import { Role } from '@shared/enums/Role';
import { ServiceController } from './service.controller';

const serviceRoutes = Router();
const serviceController = new ServiceController();

serviceRoutes.post(
  '/',
  authMiddleware,
  roleMiddleware(Role.PROVIDER),
  (req, res, next) => serviceController.create(req, res, next),
);

serviceRoutes.get(
  '/',
  authMiddleware,
  (req, res, next) => serviceController.list(req, res, next),
);

serviceRoutes.get(
  '/mine',
  authMiddleware,
  roleMiddleware(Role.PROVIDER),
  (req, res, next) => serviceController.listMine(req, res, next),
);

serviceRoutes.get(
  '/:id',
  authMiddleware,
  (req, res, next) => serviceController.getById(req, res, next),
);

serviceRoutes.patch(
  '/:id',
  authMiddleware,
  roleMiddleware(Role.PROVIDER),
  (req, res, next) => serviceController.update(req, res, next),
);

export { serviceRoutes };
